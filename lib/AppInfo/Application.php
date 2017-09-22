<?php

namespace OCA\ReadItLater\AppInfo;

use Dompdf\Dompdf;
use Graby\Graby;
use OCA\ReadItLater\Controller\ReadItLaterController;
use OCA\ReadItLater\Database\EntryMapper;
use OCA\ReadItLater\ReadItLaterService;
use OCA\ReadItLater\Storage\ReadItLaterStorage;
use OCP\AppFramework\App;
use OCP\AppFramework\IAppContainer;

class Application extends App {

	/**
	 * @param array $urlParams
	 */
	public function __construct(array $urlParams = array()) {
		parent::__construct('read_it_later', $urlParams);

		$container = $this->getContainer();

		$container->registerService('EntryMapper', function(IAppContainer $container) {
			return new EntryMapper(
				$container->query('OCP\\IDb')
			);
		});

		$container->registerService('ReadItLaterController', function(IAppContainer $container) {
			return new ReadItLaterController(
				$container->query('AppName'),
				$container->query('Request'),
				$container->query('userId'),
				$container->query('ReadItLaterService')
			);
		});

		$container->registerService('ReadItLaterService', function(IAppContainer $container) {
			return new ReadItLaterService(
				$container->query('Graby'),
				$container->query('DomPDF'),
				$container->query('ReadItLaterStorage'),
				$container->query('EntryMapper')
			);
		});

		$container->registerService('ReadItLaterStorage', function(IAppContainer $container) {
			return new ReadItLaterStorage(
				$container->query('OCP\\Files\\IRootFolder')
					->getUserFolder($container->query('userId'))
			);
		});

		$container->registerService('Graby', function() {
			return new Graby();
		});

		$container->registerService('DomPDF', function() {
			return new Dompdf();
		});
	}
}
