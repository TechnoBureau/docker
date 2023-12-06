<?php
// src/Controller/PingController.php
namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\JsonResponse;


class PingController extends AbstractController
{
    #[Route('/ping', name: 'ping', methods: ['GET', 'HEAD'] )]
    public function list(): JsonResponse
    {
        // ...
        //return new Response('Hello, Symfony!');
        $data = [
          'message' => 'Hello, this is JSON response from Symfony!',
          'timestamp' => time(),
      ];

      // Return the JSON response with the data and a 200 status code
      return new JsonResponse($data);
    }
}