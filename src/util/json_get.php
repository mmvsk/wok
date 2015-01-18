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
 * JSON key/value store getter.
 *
 * Usage: json_get <file> <key>
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
		error('Usage: '.(! empty($argv[0]) ? $argv[0] : 'json_get').' <file> <key>');
	}

	$file = $argv[1];
	$key  = $argv[2];

	if (! is_file($file) || ! is_readable($file)) {
		error("File {$file} does not exist or is not readable");
	}

	$data = data_fromJsonFile($file);
	if (is_null($data)) {
		error("Could not parse {$file}");
	}

	if (! array_key_exists($key, $data)) {
		error("Key {$key} not present in {$file}");
	}

	print $data[$key].PHP_EOL;
	exit(0);
}

main($_SERVER['argc'], $_SERVER['argv']);
