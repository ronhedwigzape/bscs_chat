class Profile {
  String? fullName;
  String? firstName;
  String? middleInitial;
  String? lastName;
  String? profileImage;

  Profile({
    this.fullName,
    this.firstName,
    this.middleInitial,
    this.lastName,
    this.profileImage,
  });

  // Convert Profile object to JSON
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'firstName': firstName,
        'middleInitial': middleInitial,
        'lastName': lastName,
        'profileImage': profileImage,
      };

  // Create Profile object from a map
  static Profile fromMap(Map<String, dynamic> map) {
    return Profile(
      fullName: map['fullName'],
      firstName: map['firstName'],
      middleInitial: map['middleInitial'],
      lastName: map['lastName'],
      profileImage: map['profileImage'],
    );
  }
}
