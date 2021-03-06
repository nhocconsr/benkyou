import 'package:floor/floor.dart';

@Entity(tableName: 'User')
class User {
  @PrimaryKey()
  final int id;
  final String username;
  final String email;
  final String uuid;
  int lvl;

  User(this.id, this.username, this.lvl, this.email, this.uuid);

  factory User.fromJSON(Map<String, dynamic> json) {
    return User(
        json['id'],
        json['username'],
        json['lvl'],
      json['email'],
      json['uuid']
    );
  }

}