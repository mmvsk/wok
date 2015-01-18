<?php

/*
 * Copyright © 2013-2015 Max Ruman <rmx@guanako.be>
 *
 * This file is part of Wok.
 *
 * Wok is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at
 * your option) any later version.
 *
 * Wok is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with Wok. If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Usage: $0 <string> <maxLength> <prefix> {-|<pool_dir>|<pool_file>}
 */

define('POOL_MAXLOOPS', -1);

function error($msg = null, $status = 1)
{
	if ($msg) {
		fputs(STDERR, $msg.PHP_EOL);
	}
	exit($status);
}

interface IPool
{
	/*
	 * @param string $string
	 * @return bool
	 */
	public function has($string);
}

/**
 * This class stores the pool in an array. May be used to store read-once streams.
 */
class ArrayPool implements IPool
{
	protected $contents = array();

	public static function fromFile($fileHandle) {
		$contents = array();
		fseek($fileHandle, 0, SEEK_SET);
		while (false !== $buf = fgets($fileHandle)) {
			$contents[] = strtok($buf, "\r\n");
		}
		return new self($contents);
	}

	public function __construct(array $contents)
	{
		$this->contents = $contents;
	}

	public function has($string)
	{
		return in_array($string, $this->contents, true);
	}
}

/**
 * Seekable file pool. This implementation allows to save some memory
 * (but is less efficient in terms of speed).
 */
class FilePool implements IPool
{
	protected $fileHandle;

	public function __construct($path)
	{
		if (! is_file($path)) {
			error("{$path} is not a file");
		}
		if (! is_readable($path)) {
			error("File {$path} is not readable");
		}
		$this->fileHandle = fopen($path, 'r');
	}

	public function __destruct()
	{
		fclose($this->fileHandle);
	}

	public function has($string)
	{
		fseek($this->fileHandle, 0, SEEK_SET);
		while (false !== $buf = fgets($this->fileHandle)) {
			$buf = strtok($buf, "\r\n");
			if ($buf === $string) {
				return true;
			}
		}
		return false;
	}
}

/**
 * Directory pool that matches the string against its files names (without cache,
 * so if you want to cache the files, use the ArrayPool instead).
 */
class DirectoryPool implements IPool
{
	protected $iterator;

	public function __construct($path)
	{
		if (! is_dir($path)) {
			error("{$path} is not a directory");
		}
		if (! is_readable($path)) {
			error("Directory {$path} is not readable");
		}
		if (! is_executable($path)) {
			error("Directory {$path} is not executable");
		}
		$this->iterator = new DirectoryIterator($path);
	}

	public function has($string)
	{
		foreach ($this->iterator as $file) {
			if ($file->isDir()) continue;
			if ($file->getFilename() === $string) {
				return true;
			}
		}
		return false;
	}
}

class StringSlugifier
{
	protected $pool;
	protected $maxLength;
	protected $prefix;

	public function __construct(IPool $pool = null, $maxLength = null, $prefix = '') {
		if (! is_null($maxLength)) {
			if ($maxLength <= 0) {
				$maxLength = null;
			} elseif (strlen($prefix) > $maxLength) {
				error('Hey dude, what do you smoke!?');
			}
		}
		$this->pool = $pool;
		$this->maxLength = $maxLength;
		$this->prefix = $prefix;
	}

	public function slugify($string) {
		$string = $this->translit($string);
		$string = $this->format($string);
		$string = $this->clean($string);
		$string = $this->prepend($string);
		$string = $this->resize($string);
		$string = $this->deduplicate($string);
		return $string;
	}

	protected function translit($string) {
		return iconv('utf-8', 'us-ascii//translit', $string);
	}

	protected function format($string) {
		return strtolower($string);
	}

	protected function clean($string) {
		return preg_replace('/[^a-z0-9]+/', null, $string);
	}

	protected function prepend($string) {
		return $this->prefix.$string;
	}

	public function resize($string) {
		if (is_null($this->maxLength)) {
			return $string;
		}
		return substr($string, 0, $this->maxLength);
	}

	protected function deduplicate($string) {
		if (is_null($this->pool)) {
			return $string;
		}
		$i = 1;
		$candidate = $string;
		while ($this->pool->has($candidate)) {
			if ($i === POOL_MAXLOOPS) {
				error('Too many loops required to find a unique string');
			}
			$no = (string) $i;
			if (is_null($this->maxLength)) {
				$candidate = $string.$no;
			} else {
				$candidate = substr($string, 0, $this->maxLength - strlen($no)).$no;
			}
			$i++;
		}
		return $candidate;
	}
}

if (! isset($_SERVER['argc']) || ! isset($_SERVER['argv'])) {
	error('Bad usage of this tool');
}

$argc = (int)   $_SERVER['argc'];
$argv = (array) $_SERVER['argv'];

if ($argc < 2) {
	error("Usage: {$argv[0]} <string> <maxLength> <prefix> {-|<pool_dir>|<pool_file>}");
}

$string    = (string) $argv[1];
$maxLength = ($argc >= 3) ?    (int) $argv[2] : null;
$prefix    = ($argc >= 4) ? (string) $argv[3] : null;
$pool      = ($argc >= 5) ? (string) $argv[4] : null;

if (! is_null($pool)) {
	if ($pool === '-') {
		$pool = ArrayPool::fromFile(STDIN);
	} elseif (is_file($pool)) {
		$pool = new FilePool($pool);
	} elseif (is_dir($pool)) {
		$pool = new DirectoryPool($pool);
	} else {
		error('Invalid pool');
	}
}

$slugifier = new StringSlugifier($pool, $maxLength, $prefix);

print $slugifier->slugify($string).PHP_EOL;
