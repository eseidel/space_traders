import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:petstore/api_client.dart';
import 'package:petstore/api_exception.dart';
import 'package:petstore/model/api_response.dart';
import 'package:petstore/model/find_pets_by_status_parameter0.dart';
import 'package:petstore/model/pet.dart';

class PetApi {
  PetApi(ApiClient? client) : client = client ?? ApiClient();

  final ApiClient client;

  Future<Pet> addPet(Pet pet) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/pet',
      body: pet.toJson(),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return Pet.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(response.statusCode, 'Unhandled response from $addPet');
  }

  Future<Pet> updatePet(Pet pet) async {
    final response = await client.invokeApi(
      method: Method.put,
      path: '/pet',
      body: pet.toJson(),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return Pet.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $updatePet',
    );
  }

  Future<List<Pet>> findPetsByStatus({
    FindPetsByStatusParameter0? status = FindPetsByStatusParameter0.available,
  }) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/pet/findByStatus',
      queryParameters: {'status': ?status?.toJson()},
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return (jsonDecode(response.body) as List)
          .map<Pet>((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $findPetsByStatus',
    );
  }

  Future<List<Pet>> findPetsByTags({List<String>? tags}) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/pet/findByTags',
      queryParameters: {'tags': tags.toString()},
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return (jsonDecode(response.body) as List)
          .map<Pet>((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $findPetsByTags',
    );
  }

  Future<Pet> getPetById(int petId) async {
    final response = await client.invokeApi(
      method: Method.get,
      path: '/pet/{petId}'.replaceAll('{petId}', '$petId'),
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return Pet.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $getPetById',
    );
  }

  Future<Pet> updatePetWithForm(
    int petId, {
    String? name,
    String? status,
  }) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/pet/{petId}'.replaceAll('{petId}', '$petId'),
      queryParameters: {'name': name.toString(), 'status': status.toString()},
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return Pet.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $updatePetWithForm',
    );
  }

  Future<void> deletePet(int petId, {String? apiKey}) async {
    final response = await client.invokeApi(
      method: Method.delete,
      path: '/pet/{petId}'.replaceAll('{petId}', '$petId'),
      headerParameters: {'api_key': ?apiKey},
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return;
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $deletePet',
    );
  }

  Future<ApiResponse> uploadFile(
    int petId, {
    String? additionalMetadata,
    String? string,
  }) async {
    final response = await client.invokeApi(
      method: Method.post,
      path: '/pet/{petId}/uploadImage'.replaceAll('{petId}', '$petId'),
      queryParameters: {'additionalMetadata': additionalMetadata.toString()},
      body: string,
    );

    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isNotEmpty) {
      return ApiResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw ApiException(
      response.statusCode,
      'Unhandled response from $uploadFile',
    );
  }
}
