<?php

/*
 * Copyright © 2013 Max Ruman
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

function error($message = null)
{
	if (! is_null($message)) {
		fputs(STDERR, $message.PHP_EOL);
	}
	exit(1);
}

function main($argc, array $argv)
{
	if (empty($argv[1]) || empty($argv[2]) || empty($argv[3])) {
		error('Usage: '.(! empty($argv[0]) ? $argv[0] : 'ini_get').' <file> <section> <key>');
	}

	$ini_file = $argv[1];
	$ini_sect = $argv[2];
	$ini_key  = $argv[3];

	if (! is_file($ini_file) || ! is_readable($ini_file)) {
		error("File {$ini_file} does not exist or is not readable");
	}

	if (! $ini_data = parse_ini_file($ini_file, true)) {
		error("Could not parse {$ini_file}");
	}

	if (! array_key_exists($ini_sect, $ini_data) || ! is_array($ini_data[$ini_sect])) {
		error("Namespace {$ini_sect} not present in {$ini_file}");
	}

	if (! array_key_exists($ini_key, $ini_data[$ini_sect])) {
		error("Key {$ini_key} not present in {$ini_file}, section {$ini_sect}");
	}

	$value = $ini_data[$ini_sect][$ini_key];

	if (is_string($value)) {
		print $value.PHP_EOL;
		exit(0);
	}

	if (is_array($value)) {
		print implode(PHP_EOL, $value).PHP_EOL;
		exit(0);
	}

	error();
}

main($_SERVER['argc'], $_SERVER['argv']);
