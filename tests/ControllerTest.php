<?php
declare(strict_types=1);

use PHPUnit\Framework\TestCase;

final class ControllerTest extends TestCase
{

	public function testCanBeUsedAsString(): void
	{
		$this->assertEquals(
			'user@example.com',
			'user2@example.com'
		);
	}
}

