import 'package:dartz/dartz.dart';
import 'package:tv_monitor/core/errors/exceptions.dart';
import 'package:tv_monitor/core/errors/failures.dart';
import 'package:tv_monitor/core/utils/typedef.dart';
import 'package:tv_monitor/features/data/datasources/remote/websocket_datasource.dart';
import 'package:tv_monitor/features/domain/entities/websocket_message_entity.dart';
import 'package:tv_monitor/features/domain/repositories/websocket_repository.dart';

class WebSocketRepositoryImpl implements WebSocketRepository {
  final WebSocketDataSource dataSource;

  WebSocketRepositoryImpl({required this.dataSource});

  @override
  ResultFuture<void> connect({required String deviceId, required String accessToken}) async {
    try {
      await dataSource.connect(deviceId: deviceId, accessToken: accessToken);
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message));
    } catch (e) {
      return Left(WebSocketFailure(message: e.toString()));
    }
  }

  @override
  Stream<WebSocketMessageEntity> get messages {
    return dataSource.messages.map((model) => model.toEntity());
  }

  @override
  ResultFuture<void> disconnect() async {
    try {
      await dataSource.disconnect();
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message));
    } catch (e) {
      return Left(WebSocketFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<bool> get isConnected async {
    try {
      return Right(dataSource.isConnected);
    } catch (e) {
      return Left(WebSocketFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> sendMessage(DataMap message) async {
    try {
      await dataSource.sendMessage(message);
      return const Right(null);
    } on WebSocketException catch (e) {
      return Left(WebSocketFailure(message: e.message));
    } catch (e) {
      return Left(WebSocketFailure(message: e.toString()));
    }
  }
}
