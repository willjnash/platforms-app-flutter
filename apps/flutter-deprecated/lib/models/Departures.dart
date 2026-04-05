class Departures {
  Location location;
  Null filter;
  List<Services> services;

  Departures({this.location, this.filter, this.services});

  Departures.fromJson(Map<String, dynamic> json) {
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
    filter = json['filter'];
    if (json['services'] != null) {
      services = new List<Services>();
      json['services'].forEach((v) {
        services.add(new Services.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.location != null) {
      data['location'] = this.location.toJson();
    }
    data['filter'] = this.filter;
    if (this.services != null) {
      data['services'] = this.services.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Location {
  String name;
  String crs;
  var tiploc;

  Location({this.name, this.crs, this.tiploc});

  Location.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    crs = json['crs'];
    tiploc = json['tiploc'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['crs'] = this.crs;
    data['tiploc'] = this.tiploc;
    return data;
  }
}

class Services {
  LocationDetail locationDetail;
  String serviceUid;
  String runDate;
  String trainIdentity;
  String runningIdentity;
  String atocCode;
  String atocName;
  String serviceType;
  bool isPassenger;

  Services(
      {this.locationDetail,
        this.serviceUid,
        this.runDate,
        this.trainIdentity,
        this.runningIdentity,
        this.atocCode,
        this.atocName,
        this.serviceType,
        this.isPassenger});

  Services.fromJson(Map<String, dynamic> json) {
    locationDetail = json['locationDetail'] != null
        ? new LocationDetail.fromJson(json['locationDetail'])
        : null;
    serviceUid = json['serviceUid'];
    runDate = json['runDate'];
    trainIdentity = json['trainIdentity'];
    runningIdentity = json['runningIdentity'];
    atocCode = json['atocCode'];
    atocName = json['atocName'];
    serviceType = json['serviceType'];
    isPassenger = json['isPassenger'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.locationDetail != null) {
      data['locationDetail'] = this.locationDetail.toJson();
    }
    data['serviceUid'] = this.serviceUid;
    data['runDate'] = this.runDate;
    data['trainIdentity'] = this.trainIdentity;
    data['runningIdentity'] = this.runningIdentity;
    data['atocCode'] = this.atocCode;
    data['atocName'] = this.atocName;
    data['serviceType'] = this.serviceType;
    data['isPassenger'] = this.isPassenger;
    return data;
  }
}

class LocationDetail {
  bool realtimeActivated;
  String tiploc;
  String crs;
  String description;
  String gbttBookedDeparture;
  List<Origin> origin;
  List<Destination> destination;
  bool isCall;
  bool isPublicCall;
  String realtimeDeparture;
  bool realtimeDepartureActual;
  String platform;
  bool platformConfirmed;
  bool platformChanged;
  String serviceLocation;
  String displayAs;

  LocationDetail(
      {this.realtimeActivated,
        this.tiploc,
        this.crs,
        this.description,
        this.gbttBookedDeparture,
        this.origin,
        this.destination,
        this.isCall,
        this.isPublicCall,
        this.realtimeDeparture,
        this.realtimeDepartureActual,
        this.platform,
        this.platformConfirmed,
        this.platformChanged,
        this.serviceLocation,
        this.displayAs});

  LocationDetail.fromJson(Map<String, dynamic> json) {
    realtimeActivated = json['realtimeActivated'];
    tiploc = json['tiploc'];
    crs = json['crs'];
    description = json['description'];
    gbttBookedDeparture = json['gbttBookedDeparture'];
    if (json['origin'] != null) {
      origin = new List<Origin>();
      json['origin'].forEach((v) {
        origin.add(new Origin.fromJson(v));
      });
    }
    if (json['destination'] != null) {
      destination = new List<Destination>();
      json['destination'].forEach((v) {
        destination.add(new Destination.fromJson(v));
      });
    }
    isCall = json['isCall'];
    isPublicCall = json['isPublicCall'];
    realtimeDeparture = json['realtimeDeparture'];
    realtimeDepartureActual = json['realtimeDepartureActual'];
    platform = json['platform'];
    platformConfirmed = json['platformConfirmed'];
    platformChanged = json['platformChanged'];
    serviceLocation = json['serviceLocation'];
    displayAs = json['displayAs'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['realtimeActivated'] = this.realtimeActivated;
    data['tiploc'] = this.tiploc;
    data['crs'] = this.crs;
    data['description'] = this.description;
    data['gbttBookedDeparture'] = this.gbttBookedDeparture;
    if (this.origin != null) {
      data['origin'] = this.origin.map((v) => v.toJson()).toList();
    }
    if (this.destination != null) {
      data['destination'] = this.destination.map((v) => v.toJson()).toList();
    }
    data['isCall'] = this.isCall;
    data['isPublicCall'] = this.isPublicCall;
    data['realtimeDeparture'] = this.realtimeDeparture;
    data['realtimeDepartureActual'] = this.realtimeDepartureActual;
    data['platform'] = this.platform;
    data['platformConfirmed'] = this.platformConfirmed;
    data['platformChanged'] = this.platformChanged;
    data['serviceLocation'] = this.serviceLocation;
    data['displayAs'] = this.displayAs;
    return data;
  }
}

class Origin {
  String tiploc;
  String description;
  String workingTime;
  String publicTime;

  Origin({this.tiploc, this.description, this.workingTime, this.publicTime});

  Origin.fromJson(Map<String, dynamic> json) {
    tiploc = json['tiploc'];
    description = json['description'];
    workingTime = json['workingTime'];
    publicTime = json['publicTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tiploc'] = this.tiploc;
    data['description'] = this.description;
    data['workingTime'] = this.workingTime;
    data['publicTime'] = this.publicTime;
    return data;
  }
}

class Destination {
  String tiploc;
  String description;
  String workingTime;
  String publicTime;

  Destination({this.tiploc, this.description, this.workingTime, this.publicTime});

  Destination.fromJson(Map<String, dynamic> json) {
    tiploc = json['tiploc'];
    description = json['description'];
    workingTime = json['workingTime'];
    publicTime = json['publicTime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tiploc'] = this.tiploc;
    data['description'] = this.description;
    data['workingTime'] = this.workingTime;
    data['publicTime'] = this.publicTime;
    return data;
  }
}
