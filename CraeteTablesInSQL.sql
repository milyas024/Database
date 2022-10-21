CREATE TABLE Vehicle_Asset (
    VehicleID int NOT NULL PRIMARY KEY,
    RegistrationID varchar(50),
    Manufacturer varchar(50),
    Model varchar(50),
    Color varchar(20),
    CurrentOdoMeter int ,
    PassangerCapicity int ,
    Available varchar(30)
);



CREATE TABLE Country (
    CountryID varchar(2) NOT NULL PRIMARY KEY,
    CountryLanguage varchar(3)
   
);

CREATE TABLE Game_officials (
    OfficialID  int NOT NULL PRIMARY KEY,
    OfficialName varchar(200),
    CityName varchar(255),
    officailRole varchar(100),
    CountryID varchar(2)  FOREIGN KEY REFERENCES Country(OfficialID)
    
);

CREATE TABLE Driver(
    Driver_LicenceNumber  varchar(18) NOT NULL PRIMARY KEY,

    Driver_Name  varchar(100) ,
    Driver_SCL             int ,
    Driver_FATL            int ,
    Driver_STLVT           int
     
     
   
);

CREATE TABLE Driver_booking_Service(

    Booking_Ref_NO varchar(18) NOT NULL PRIMARY KEY,
    Driver_LicenceNumber  varchar(18)  FOREIGN KEY REFERENCES Driver(VehicleID),
    VehicleID varchar(20)  FOREIGN KEY REFERENCES Vehicle_Asset(VehicleID),
    OfficialID int  FOREIGN KEY REFERENCES Game_officials(OfficialID),
    BookingLocation varchar(18),
    Bookingtye varchar(30),
    Booking_Ref_NO  varchar(18),
    Trip_Start_Date   DATE ,
    Trip_End_Date     DATE ,
    Start_odometer     int,
    End_odometer     int
     
     
   
);













