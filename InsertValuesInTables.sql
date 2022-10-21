
--- INSERT VALUES IN TABLE  Vehicle_Asset


INSERT INTO Vehicle_Asset (VehicleID, RegistrationID, Manufacturer, Model, Color, CurrentOdoMeter,PassangerCapicity,Available )
VALUES ('V1000', '2001ABC' ,'Volvo', 'XC90SE', 'Silver', '4350', '4','Available');

INSERT INTO Vehicle_Asset (VehicleID, RegistrationID, Manufacturer, Model, Color, CurrentOdoMeter,PassangerCapicity,Available )
VALUES ('V1001', '2006AFD' ,'kia', 'K7', 'Black', '2195', '4','Available');

INSERT INTO Vehicle_Asset (VehicleID, RegistrationID, Manufacturer, Model, Color, CurrentOdoMeter,PassangerCapicity,Available )
VALUES ('V1002', '2021AHR' ,'tesla', '2020F', 'White', '509', '4','Available');

INSERT INTO Vehicle_Asset (VehicleID, RegistrationID, Manufacturer, Model, Color, CurrentOdoMeter,PassangerCapicity,Available )
VALUES ('V1003', '2020DXF' ,'Ford', 'Transit', 'Silver', '974', '2','Available');



--- INSERT VALUES IN TABLE  Country


INSERT INTO Country (CountryID, CountryLanguage ,CountryName)
VALUES ('KR', 'Korean','Korea');

INSERT INTO Country (CountryID, CountryLanguage ,CountryName)
VALUES ('PK', 'Urdu','Pakistan');




--- INSERT VALUES IN TABLE  Game_officials



INSERT INTO Game_officials (OfficialID,  OfficialName ,CityName,officailRole,CountryID)
VALUES ('1', 'Ilyas','Islamabad','Coach','PK');

INSERT INTO Game_officials (OfficialID,  OfficialName ,CityName,officailRole,CountryID)
VALUES ('2', 'John','Lahore','Judge','PK');

INSERT INTO Game_officials (OfficialID,  OfficialName ,CityName,officailRole,CountryID)
VALUES ('3', 'John','Busan','Physcian','KR');




--- INSERT VALUES IN TABLE  Driver


INSERT INTO Driver (Driver_LicenceNumber, driver_name, Driver_SCL ,Driver_FATL, Driver_STLVT)
VALUES ('1234567ABCDEFGHJKL', 'Khalid','2','8','4');

INSERT INTO Driver (Driver_LicenceNumber, driver_name, Driver_SCL ,Driver_FATL, Driver_STLVT)
VALUES ('9999999ABCDEFGHJKL', 'Qsim','4','7','3');

INSERT INTO Driver (Driver_LicenceNumber, driver_name, Driver_SCL ,Driver_FATL, Driver_STLVT)
VALUES ('777777ABCDEFGHJKL', 'Akbar','2','9','2');

INSERT INTO Driver (Driver_LicenceNumber, driver_name, Driver_SCL ,Driver_FATL, Driver_STLVT)
VALUES ('888888ABCDEFGHJKL', 'Waleed','2','6','4');




--- INSERT VALUES IN TABLE  Driver_booking_Service


INSERT INTO Driver_booking_Service (Booking_Ref_NO, Driver_LicenceNumber, VehicleID ,OfficialID, BookingLocation,Bookingtye,Trip_Start_Date,Trip_End_Date,Start_odometer,End_odometer)
VALUES ('2222228899AABBCC', '888888ABCDEFGHJKL','V1000','1','CANADA Tronto street6','Hote','18-oct-2022','20-oct-2022','5000','10000');


INSERT INTO Driver_booking_Service (Booking_Ref_NO, Driver_LicenceNumber, VehicleID ,OfficialID, BookingLocation,Bookingtye,Trip_Start_Date,Trip_End_Date,Start_odometer,End_odometer)
VALUES ('2222228899DDFFGG', '777777ABCDEFGHJKL','V1003','2','ITLY Rome','Airport','15-oct-2022','17-oct-2022','7000','9000');


















