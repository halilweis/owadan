<?php
namespace App\EventSubscriber;

use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpKernel\Event\ExceptionEvent;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

#[AsEventListener(event: 'kernel.exception')]
final class ApiExceptionSubscriber
{
    public function __invoke(ExceptionEvent $event): void
    {
        $request = $event->getRequest();
        if (!str_starts_with($request->getPathInfo(), '/api/')) { return; }
        $e = $event->getThrowable();
        $status = $e instanceof HttpExceptionInterface ? $e->getStatusCode() : 500;
        $message = $status >= 500 ? 'Internal server error' : $e->getMessage();
        $event->setResponse(new JsonResponse([
            'error' => [
                'code' => $status >= 500 ? 'INTERNAL_ERROR' : 'HTTP_ERROR',
                'message' => $message,
            ]
        ], $status));
    }
}
