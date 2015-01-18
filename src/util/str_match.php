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

exit((
	   isset($_SERVER['argv'][1]) && is_string($_SERVER['argv'][1])
	&& isset($_SERVER['argv'][2]) && is_string($_SERVER['argv'][2])
	&& @preg_match($_SERVER['argv'][1], $_SERVER['argv'][2])
) ? 0:1);
