class ServiceDetail {
  String serviceUid;
  String runDate;
  String serviceType;
  bool isPassenger;
  String trainIdentity;
  String powerType;
  String trainClass;
  String atocCode;
  String atocName;
  bool performanceMonitored;
  List<Origin> origin;
  List<Destination> destination;
  List<Locations> locations;
  bool realtimeActivated;
  String runningIdentity;

  ServiceDetail(
      {this.serviceUid,
        this.runDate,
        this.serviceType,
        this.isPassenger,
        this.trainIdentity,
        this.powerType,
        this.trainClass,
        this.atocCode,
        this.atocName,
        this.performanceMonitored,
        this.origin,
        this.destination,
        this.locations,
        this.realtimeActivated,
        this.runningIdentity});

  ServiceDetail.fromJson(Map<String, dynamic> json) {
    serviceUid = json['serviceUid'];
    runDate = json['runDate'];
    serviceType = json['serviceType'];
    isPassenger = json['isPassenger'];
    trainIdentity = json['trainIdentity'];
    powerType = json['powerType'];
    trainClass = json['trainClass'];
    atocCode = json['atocCode'];
    atocName = json['atocName'];
    performanceMonitored = json['performanceMonitored'];
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
    if (json['locations'] != null) {
      locations = new List<Locations>();
      json['locations'].forEach((v) {
        locations.add(new Locations.fromJson(v));
      });
    }
    realtimeActivated = json['realtimeActivated'];
    runningIdentity = json['runningIdentity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['serviceUid'] = this.serviceUid;
    data['runDate'] = this.runDate;
    data['serviceType'] = this.serviceType;
    data['isPassenger'] = this.isPassenger;
    data['trainIdentity'] = this.trainIdentity;
    data['powerType'] = this.powerType;
    data['trainClass'] = this.trainClass;
    data['atocCode'] = this.atocCode;
    data['atocName'] = this.atocName;
    data['performanceMonitored'] = this.performanceMonitored;
    if (this.origin != null) {
      data['origin'] = this.origin.map((v) => v.toJson()).toList();
    }
    if (this.destination != null) {
      data['destination'] = this.destination.map((v) => v.toJson()).toList();
    }
    if (this.locations != null) {
      data['locations'] = this.locations.map((v) => v.toJson()).toList();
    }
    data['realtimeActivated'] = this.realtimeActivated;
    data['runningIdentity'] = this.runningIdentity;
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

class Locations {
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
  String line;
  bool lineConfirmed;
  String displayAs;
  String gbttBookedArrival;
  String realtimeArrival;
  bool realtimeArrivalActual;

  Locations(
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
        this.line,
        this.lineConfirmed,
        this.displayAs,
        this.gbttBookedArrival,
        this.realtimeArrival,
        this.realtimeArrivalActual});

  Locations.fromJson(Map<String, dynamic> json) {
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
    line = json['line'];
    lineConfirmed = json['lineConfirmed'];
    displayAs = json['displayAs'];
    gbttBookedArrival = json['gbttBookedArrival'];
    realtimeArrival = json['realtimeArrival'];
    realtimeArrivalActual = json['realtimeArrivalActual'];
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
    data['line'] = this.line;
    data['lineConfirmed'] = this.lineConfirmed;
    data['displayAs'] = this.displayAs;
    data['gbttBookedArrival'] = this.gbttBookedArrival;
    data['realtimeArrival'] = this.realtimeArrival;
    data['realtimeArrivalActual'] = this.realtimeArrivalActual;
    return data;
  }
}

