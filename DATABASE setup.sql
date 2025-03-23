 Drop the database if it exists
DROP DATABASE IF EXISTS lms_dev;
CREATE DATABASE lms_dev;
USE lms_dev;
SET GLOBAL local_infile = 1;
SHOW TABLES;

-- Create Centers table and load data
DROP TABLE IF EXISTS Centers;
CREATE TABLE Centers (
    Center_ID VARCHAR(10) PRIMARY KEY
);

LOAD DATA LOCAL INFILE 'C:/Users/seham/StageOne/Centers.csv'
INTO TABLE Centers
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Create Student_Status table and load data
DROP TABLE IF EXISTS Student_Status;
CREATE TABLE Student_Status (
    Student_ID VARCHAR(10) PRIMARY KEY,
    Center_ID VARCHAR(10),
    Target_Level VARCHAR(10)
);

LOAD DATA LOCAL INFILE 'C:/Users/seham/StageOne/Student Status.csv' 
INTO TABLE Student_Status
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Clean up Target_Level data
UPDATE Student_Status SET Target_Level = REPLACE(Target_Level, '\r', '');
UPDATE Student_Status SET Target_Level = 'Unknown' WHERE Target_Level IS NULL OR Target_Level = '' OR TRIM(Target_Level) = '';
UPDATE Student_Status SET Target_Level = 'multiple' WHERE Target_Level LIKE '%+%';
UPDATE Student_Status SET Target_Level = '3' WHERE (Target_Level LIKE '%3%' OR Target_Level LIKE '%Only%' OR Target_Level = '3.4') AND Target_Level NOT LIKE '%+%';
UPDATE Student_Status SET Target_Level = '2' WHERE Target_Level LIKE '%2%' AND Target_Level NOT LIKE '%3%' AND Target_Level NOT LIKE '%+%';
UPDATE Student_Status SET Target_Level = '1' WHERE Target_Level = '1';

SELECT Target_Level, COUNT(*) FROM Student_Status GROUP BY Target_Level;

-- Create Change_Requests table and load data
DROP TABLE IF EXISTS Change_Requests;
CREATE TABLE Change_Requests (
    Student_ID VARCHAR(10),             
    Center_ID VARCHAR(10),               
    Level VARCHAR(5),                             
    Course_Name VARCHAR(100),                     
    Previous_Cohort VARCHAR(10),                 
    Request_Date VARCHAR(50),                          
    Request_Type VARCHAR(50),                     
    Rescheduled_Cohort VARCHAR(10),               
    Withdrawal_Reason VARCHAR(200)
);

LOAD DATA LOCAL INFILE 'C:/Users/seham/StageOne/Change Requests.tsv'
INTO TABLE Change_Requests
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Format Request_Date field
ALTER TABLE Change_Requests ADD COLUMN Request_Date_New DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE Change_Requests SET Request_Date_New = CASE 
    WHEN Request_Date = '""' OR Request_Date = '' THEN NULL
    ELSE STR_TO_DATE(Request_Date, '%m/%d/%Y')
END;
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE Change_Requests DROP COLUMN Request_Date, CHANGE COLUMN Request_Date_New Request_Date DATE;

-- Clean data and handle null values
UPDATE Change_Requests SET Rescheduled_Cohort = 'Unknown' WHERE HEX(Rescheduled_Cohort) = '2222';
UPDATE Change_Requests SET Withdrawal_Reason = 'Unknown' WHERE HEX(Withdrawal_Reason) = '0D';
UPDATE Change_Requests SET Request_Date = 'Unknown' WHERE HEX(Request_Date) = '2222';
UPDATE Change_Requests SET Previous_Cohort = 'Unknown' WHERE HEX(Previous_Cohort) = '2222';
UPDATE Change_Requests SET Request_Type = 'Unknown' WHERE HEX(Request_Type) = '2222';

-- Validate level values
SELECT * FROM Change_Requests WHERE LEVEL < 1 OR LEVEL > 10;

-- Create Cohort_Assignment table and load data
DROP TABLE IF EXISTS Cohort_Assignment;
CREATE TABLE Cohort_Assignment (
    Student_ID VARCHAR(10) NOT NULL,              
    Center_ID VARCHAR(10) NOT NULL,              
    Level VARCHAR(5),                             
    Course_Name VARCHAR(100),                     
    Cohort VARCHAR(10),                           
    Start VARCHAR(20),                              
    End VARCHAR(20),                                
    Cohort_Schedule VARCHAR(50),                  
    Cohort_Status VARCHAR(20),                    
    Enrollment_Confirmation VARCHAR(20),          
    Withdrawal_Reason1 VARCHAR(100),              
    Withdrawal_Reason2 VARCHAR(100),              
    Level_Status INT,                            
    New_Joiner VARCHAR(20),                       
    Level_Graduation_Indicator VARCHAR(5),       
    Attendance_Rate DECIMAL(5,2),                 
    Quiz_Completion INT,                          
    Project_Submission VARCHAR(20)
);

LOAD DATA LOCAL INFILE 'C:/Users/seham/StageOne/Cohort Assignment.tsv'
INTO TABLE Cohort_Assignment
FIELDS TERMINATED BY '\t'  
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Convert date fields
ALTER TABLE Cohort_Assignment ADD COLUMN Start_New DATE, ADD COLUMN End_New DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE Cohort_Assignment SET Start_New = STR_TO_DATE(Start, '%d-%b-%Y'), End_New = STR_TO_DATE(End, '%d-%b-%Y');
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE Cohort_Assignment DROP COLUMN Start, DROP COLUMN End, CHANGE COLUMN Start_New Start DATE, CHANGE COLUMN End_New End DATE;

-- Clean Cohort_Assignment data
UPDATE Cohort_Assignment SET Level_Graduation_Indicator = 'Unknown' WHERE HEX(Level_Graduation_Indicator) = '2222';
UPDATE Cohort_Assignment SET New_Joiner = 'Unknown' WHERE HEX(New_Joiner) = '2222';
UPDATE Cohort_Assignment SET Withdrawal_Reason2 = 'Unknown' WHERE HEX(Withdrawal_Reason2) = '2222';
UPDATE Cohort_Assignment SET Withdrawal_Reason1 = 'Unknown' WHERE HEX(Withdrawal_Reason1) = '2222';
UPDATE Cohort_Assignment SET Enrollment_Confirmation = 'Unknown' WHERE HEX(Enrollment_Confirmation) = '2222';

-- Validate missing values
SELECT * FROM Cohort_Assignment WHERE Student_ID IS NULL OR Center_ID IS NULL OR Level IS NULL OR Course_Name IS NULL OR Cohort IS NULL OR Start IS NULL OR End IS NULL;

-- Load attendance records
LOAD DATA LOCAL INFILE 'C:/Users/seham/StageOne/Merged_Attendance.csv' 
INTO TABLE Attendance_Records
FIELDS TERMINATED BY ','  
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Student_ID, Course_Name, Cohort , @Attendance_Date, attendance_flage)
SET Attendance_Date = STR_TO_DATE(@Attendance_Date,'%d-%m-%Y');
