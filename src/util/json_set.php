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

/**
 * JSON key/value store setter.
 *
 * Usage: json_set <file> <key> [<value>]
 *
 * If <value> is omitted, the key will be deleted.
 */

function error($message = null)
{
	if (! is_null($message)) {
		fputs(STDERR, $message.PHP_EOL);
	}
	exit(1);
}

function data_fromJsonFile($path)
{
	$json = file_get_contents($path);
	return json_decode($json, true);
}

function data_toJsonFile(array $data, $path)
{
	$json = json_encode($data, JSON_PRETTY_PRINT).PHP_EOL;
	file_put_contents($path, $json);
}

function main($argc, array $argv)
{
	if (empty($argv[1]) || empty($argv[2])) {
		error('Usage: '.(! empty($argv[0]) ? $argv[0] : 'json_set').' <file> <key> [<value>]');
	}

	$file  = $argv[1];
	$key   = $argv[2];
	$value = isset($argv[3]) ? $argv[3] : null;
	$data  = array();

	if (is_file($file)) {
		if (! is_readable($file)) {
			error("File {$file} exists but is not readable");
		}

		if (! is_writable($file)) {
			error("File {$file} exists but is not writable");
		}

		$data = data_fromJsonFile($file);
		if (is_null($data)) {
			error("Could not parse {$file}");
		}
	}

	if (is_null($value)) {
		if (isset($data[$key])) {
			unset($data[$key]);
		}
	} else {
		$data[$key] = $value;
	}
	data_toJsonFile($data, $file);
	exit(0);
}

main($_SERVER['argc'], $_SERVER['argv']);
