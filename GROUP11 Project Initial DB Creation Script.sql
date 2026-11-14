-- GROUP 11: GUN PERMITS AND ISSUANCE MANAGEMENT
-- Database: G11_gunpermit | MySQL 8.0 / InnoDB
-- Regenerated 03 November 2026: creation scripts ALWAYS include population.
-- Scope: approved simplified administrative permit-document processing,
-- not a real statutory licensing implementation. All individual records,
-- document references, makers, models, and firearm identifiers are invented.
-- No actual government, applicant, or firearm records were used.
-- Seed: 110362. Application activity: 2024-11-01 through 2026-10-31
-- (24 consecutive calendar months). Operational as-of date: 2026-11-03.
-- Earlier registration records provide necessary supporting history.
-- Future validto values describe prospective validity, not completed events.
-- Receipt amounts and 365-day validity intervals are case assumptions,
-- not statutory fees or legal validity periods. No full-payment rule assumed.
-- Locality codes and labels belong to the invented case organization.
-- Optional phone values are NULL to avoid generating real contact numbers.
-- TABLE COUNTS: applicants=210, firearms=185, applications=730, submissions=2276, payments=714, permits=488.
--
-- Run once in a new/empty database. No existing tables are overwritten.
-- This is not a rerunnable reset or migration script; no DROP statements.
-- DDL commits independently. Seed INSERTs use one transaction; if any INSERT
-- fails, stop execution and ROLLBACK rather than continuing to COMMIT.
-- Use a MySQL client configured to stop on errors; do not use force/continue.
-- Use strict SQL mode and the privileges needed for CREATE/ALTER/INSERT.
-- No CHECK clauses, explicit character sets, standalone index declarations,
-- triggers, stored routines, or disabled referential checks are used.
-- Data was validated computationally in Python, not executed in MySQL.
-- Report SELECT statements are not included in this creation/population file.


CREATE DATABASE IF NOT EXISTS G11_gunpermit;
USE G11_gunpermit;

CREATE TABLE applicants (
 appl_no VARCHAR(16) NOT NULL, lastname VARCHAR(80) NOT NULL,
 frstname VARCHAR(80) NOT NULL, midname VARCHAR(80) NULL,
 birthdt DATE NOT NULL, address VARCHAR(200) NOT NULL,
 loccode VARCHAR(12) NOT NULL, locname VARCHAR(100) NOT NULL,
 phone VARCHAR(30) NULL, regdate DATE NOT NULL,
 PRIMARY KEY (appl_no)
) ENGINE = InnoDB;
CREATE TABLE firearms (
 gun_no VARCHAR(16) NOT NULL, serialno VARCHAR(60) NOT NULL,
 maker VARCHAR(80) NOT NULL, model VARCHAR(80) NOT NULL,
 guntype ENUM('Handgun','Rifle','Shotgun','Other') NOT NULL,
 regref VARCHAR(60) NULL, recdate DATE NOT NULL,
 PRIMARY KEY (gun_no)
) ENGINE = InnoDB;
CREATE TABLE applications (
 app_no VARCHAR(20) NOT NULL, appl_no VARCHAR(16) NOT NULL,
 gun_no VARCHAR(16) NOT NULL, appdate DATE NOT NULL,
 appkind ENUM('New','Renewal','Replacement') NOT NULL,
 appstat ENUM('Submitted','UnderReview','Approved','Rejected','Withdrawn')
   NOT NULL DEFAULT 'Submitted',
 decdate DATE NULL, loccode VARCHAR(12) NOT NULL,
 locname VARCHAR(100) NOT NULL, proofref VARCHAR(60) NULL,
 proofdt DATE NULL, prevperm VARCHAR(20) NULL, renwhy VARCHAR(250) NULL,
 lostdate DATE NULL, lossref VARCHAR(60) NULL,
 PRIMARY KEY (app_no),
 CONSTRAINT fk_applicant_application FOREIGN KEY (appl_no)
   REFERENCES applicants(appl_no) ON DELETE RESTRICT ON UPDATE RESTRICT,
 CONSTRAINT fk_firearm_application FOREIGN KEY (gun_no)
   REFERENCES firearms(gun_no) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;
CREATE TABLE submissions (
 app_no VARCHAR(20) NOT NULL, docseq SMALLINT UNSIGNED NOT NULL,
 doccat ENUM('Identity','Registration','Acquisition','PriorPermit','Incident','Other') NOT NULL,
 docref VARCHAR(60) NULL, recvdate DATE NOT NULL,
 review ENUM('Pending','Accepted','NeedsCorrection') NOT NULL DEFAULT 'Pending',
 revdate DATE NULL, remarks VARCHAR(500) NULL,
 PRIMARY KEY (app_no,docseq),
 CONSTRAINT fk_application_submission FOREIGN KEY (app_no)
   REFERENCES applications(app_no) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;
CREATE TABLE payments (
 rcpt_no VARCHAR(24) NOT NULL, app_no VARCHAR(20) NOT NULL,
 paydate DATE NOT NULL, amount DECIMAL(12,2) NOT NULL,
 paymode ENUM('Cash','BankTransfer','Online') NOT NULL,
 PRIMARY KEY (rcpt_no),
 CONSTRAINT fk_application_payment FOREIGN KEY (app_no)
   REFERENCES applications(app_no) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;
CREATE TABLE permits (
 perm_no VARCHAR(20) NOT NULL, app_no VARCHAR(20) NOT NULL,
 issuedt DATE NOT NULL, validfr DATE NOT NULL, validto DATE NOT NULL,
 permstat ENUM('Issued','Suspended','Revoked') NOT NULL DEFAULT 'Issued',
 PRIMARY KEY(perm_no),
 CONSTRAINT uq_permit_application UNIQUE(app_no),
 CONSTRAINT fk_application_permit FOREIGN KEY(app_no)
   REFERENCES applications(app_no) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;
ALTER TABLE applications ADD CONSTRAINT fk_previous_permit_renewal
 FOREIGN KEY(prevperm) REFERENCES permits(perm_no)
 ON DELETE RESTRICT ON UPDATE RESTRICT;


-- APPLICATION VALIDATION REQUIRED AT SAVE TIME
-- Primary/foreign keys, UNIQUE, NOT NULL and ENUM do not enforce all rules.
-- Reject required blank text and invalid locality code/name pairs.
-- Enforce date chronology, positive amounts, and positive within-app docseq.
-- Preserve identifying references in ordinary edits and protect valid history.
-- New uses proofref/proofdt; Renewal uses prevperm/renwhy; Replacement uses
-- lostdate/lossref. Inapplicable values stay NULL. Applicable supporting data
-- is mandatory before approval; incomplete submissions may remain pending.
-- Renewal must concern the same applicant/firearm as its preceding permit;
-- that permit must predate this application and cannot come from this app.
-- Replacement is limited to lost-document replacement in this case.
-- Approved/Rejected require decdate; Submitted/UnderReview/Withdrawn do not
-- have a decision date. This schema has no withdrawal timestamp.
-- Pending document reviews have no revdate; other results require revdate.
-- NeedsCorrection requires explanatory remarks. Review follows receipt.
-- Issue only from an Approved application. issuedt follows the decision;
-- validfr follows or equals issue; validto follows or equals validfr.
-- Issued is an administrative status, not a claim that a date-expired permit
-- is currently usable. Compare the declared as-of date with validity dates.
-- Suspension and revocation remain distinct from date-based expiration.
-- Payments are positive receipted amounts; refunds/reversals are out of scope.
-- Applicant current locality and application-time locality are distinct facts.
-- Prevent updates that invalidate issued history; do not silently cascade
-- deletion. Coordinate grouped saves with transactions and prevent stale
-- overwrites using an approved mechanism, without assuming extra fields.
-- Original schema structure, category values, and relationship meanings are
-- retained. Lookup and subtype tables are deliberately not preimplemented.
-- The four report requirements must continue to work against this structure.


START TRANSACTION;

INSERT INTO applicants (appl_no, lastname, frstname, midname, birthdt, address, loccode, locname, phone, regdate) VALUES
('AP-00001', 'Bernardo', 'Paolo', 'Navarro', '1964-06-10', 'Unit 6B, 50 Molave Street', 'LC01', 'Luntian Central', NULL, '2024-08-12'),
('AP-00002', 'Castillo', 'Carlo', 'Tuazon', '1992-11-11', '228 Talisay Road', 'LC07', 'Pulo Verde', NULL, '2024-08-03'),
('AP-00003', 'Lim', 'Eduardo', NULL, '1990-04-16', 'Unit 2B, 22 Sampaguita Lane', 'LC05', 'Santa Elena', NULL, '2024-06-08'),
('AP-00004', 'Velasco', 'Camille', 'Serrano', '1988-05-17', 'Unit 6B, 28 Acacia Road', 'LC01', 'Luntian Central', NULL, '2024-07-15'),
('AP-00005', 'Domingo', 'Alfredo', 'Mercado', '1977-03-21', '214 Sampaguita Lane', 'LC03', 'Mabini East', NULL, '2024-07-02'),
('AP-00006', 'Villanueva', 'Rafael', 'Tan', '1999-10-27', 'Unit 7B, 52 Rosal Drive', 'LC03', 'Mabini East', NULL, '2024-09-11'),
('AP-00007', 'Domingo', 'Adrian', 'Tan', '1978-12-15', '256 Sampaguita Lane', 'LC01', 'Luntian Central', NULL, '2024-05-24'),
('AP-00008', 'Ramos', 'Rafael', 'Tolentino', '1964-10-12', 'Unit 7B, 25 Bamboo Lane', 'LC02', 'San Isidro Heights', NULL, '2024-07-02'),
('AP-00009', 'Francisco', 'Grace', 'Alcantara', '1962-03-23', '262 Mabini Avenue', 'LC02', 'San Isidro Heights', NULL, '2024-08-01'),
('AP-00010', 'Serrano', 'Emilio', 'Flores', '1988-07-13', '201 Talisay Road', 'LC07', 'Pulo Verde', NULL, '2024-05-16'),
('AP-00011', 'Ocampo', 'Miguel', 'Salazar', '1996-12-07', '87 Bamboo Lane', 'LC03', 'Mabini East', NULL, '2024-05-29'),
('AP-00012', 'Ramos', 'Grace', 'Aquino', '1973-04-25', 'Block 1 Lot 22, Mabini Avenue', 'LC01', 'Luntian Central', NULL, '2024-08-03'),
('AP-00013', 'Soriano', 'Carlo', 'Estrada', '1997-11-06', 'Unit 5B, 17 Mabini Avenue', 'LC06', 'Maligaya', NULL, '2024-10-23'),
('AP-00014', 'Marquez', 'Patricia', 'Pascual', '1993-07-18', 'Block 16 Lot 9, Sampaguita Lane', 'LC05', 'Santa Elena', NULL, '2024-07-27'),
('AP-00015', 'Aguilar', 'Enrico', 'Velasco', '1998-01-01', 'Unit 8B, 44 Mabini Avenue', 'LC03', 'Mabini East', NULL, '2024-10-16'),
('AP-00016', 'Abad', 'Marielle', 'Fajardo', '1987-11-18', 'Block 9 Lot 26, Narra Street', 'LC06', 'Maligaya', NULL, '2024-05-15'),
('AP-00017', 'Alcantara', 'Emilio', 'Fajardo', '1995-02-09', 'Block 14 Lot 31, Molave Street', 'LC03', 'Mabini East', NULL, '2024-06-30'),
('AP-00018', 'Marquez', 'Bianca', NULL, '1993-05-24', 'Block 7 Lot 1, Acacia Road', 'LC05', 'Santa Elena', NULL, '2024-05-21'),
('AP-00019', 'Francisco', 'Carlo', 'Alcantara', '1999-11-23', 'Unit 6B, 44 Acacia Road', 'LC04', 'Bagong Silangan', NULL, '2024-08-26'),
('AP-00020', 'Tuazon', 'Francis', 'Serrano', '1961-04-23', 'Unit 1B, 87 Bamboo Lane', 'LC03', 'Mabini East', NULL, '2024-10-23'),
('AP-00021', 'Tuazon', 'Ma. Cecilia', NULL, '1988-07-04', '192 Molave Street', 'LC03', 'Mabini East', NULL, '2024-09-19'),
('AP-00022', 'Fajardo', 'Rafael', NULL, '1992-01-25', '17 Molave Street', 'LC05', 'Santa Elena', NULL, '2024-05-29'),
('AP-00023', 'Aquino', 'Theresa', 'Cabrera', '1984-08-15', 'Block 11 Lot 20, Mabini Avenue', 'LC04', 'Bagong Silangan', NULL, '2024-07-19'),
('AP-00024', 'Cabrera', 'Antonio', 'Navarro', '1970-03-28', 'Unit 3B, 40 Acacia Road', 'LC07', 'Pulo Verde', NULL, '2024-08-10'),
('AP-00025', 'Villanueva', 'Jose Luis', 'Dela Cruz', '1982-03-17', '94 Talisay Road', 'LC03', 'Mabini East', NULL, '2024-10-28'),
('AP-00026', 'Soriano', 'Roberto', 'Bautista', '1994-02-09', 'Unit 2B, 27 Kalayaan Avenue', 'LC03', 'Mabini East', NULL, '2024-05-06'),
('AP-00027', 'Flores', 'Adrian', 'Bernardo', '1996-01-02', '136 Rosal Drive', 'LC04', 'Bagong Silangan', NULL, '2024-06-27'),
('AP-00028', 'Mendoza', 'Rafael', 'Villanueva', '1961-07-28', 'Block 5 Lot 10, Kalayaan Avenue', 'LC01', 'Luntian Central', NULL, '2024-10-04'),
('AP-00029', 'Abad', 'Gabriel', 'Francisco', '1980-01-12', 'Unit 4B, 78 Molave Street', 'LC02', 'San Isidro Heights', NULL, '2024-07-24'),
('AP-00030', 'Marquez', 'Ma. Cecilia', 'Salazar', '1983-03-06', '233 Mabini Avenue', 'LC01', 'Luntian Central', NULL, '2024-09-08'),
('AP-00031', 'Aquino', 'Eduardo', 'Domingo', '2000-06-21', '265 Rosal Drive', 'LC04', 'Bagong Silangan', NULL, '2024-09-27'),
('AP-00032', 'Santos', 'Eduardo', 'Pineda', '1962-11-15', 'Unit 3B, 88 Rosal Drive', 'LC08', 'San Rafael Norte', NULL, '2024-06-04'),
('AP-00033', 'Garcia', 'Joanna', 'Cabrera', '1996-05-01', '27 Narra Street', 'LC01', 'Luntian Central', NULL, '2024-10-10'),
('AP-00034', 'Santos', 'Victor', 'Pascual', '1998-11-07', '130 Talisay Road', 'LC04', 'Bagong Silangan', NULL, '2024-08-07'),
('AP-00035', 'Marquez', 'Jose Luis', 'Castillo', '1971-10-09', '59 Bamboo Lane', 'LC02', 'San Isidro Heights', NULL, '2024-10-06'),
('AP-00036', 'Aquino', 'Danica', 'Mercado', '1989-08-12', 'Unit 4B, 89 Mabini Avenue', 'LC06', 'Maligaya', NULL, '2024-07-15'),
('AP-00037', 'Bautista', 'Liza', 'Villanueva', '1962-03-21', 'Unit 4B, 55 Ilang-Ilang Street', 'LC07', 'Pulo Verde', NULL, '2024-10-19'),
('AP-00038', 'Fajardo', 'Bianca', 'Marquez', '1964-04-22', '233 Molave Street', 'LC03', 'Mabini East', NULL, '2024-05-27'),
('AP-00039', 'Bautista', 'Antonio', 'De Leon', '1994-08-12', '38 Mabini Avenue', 'LC01', 'Luntian Central', NULL, '2024-05-14'),
('AP-00040', 'Abad', 'Bianca', 'Mercado', '1980-06-07', 'Block 6 Lot 24, Narra Street', 'LC07', 'Pulo Verde', NULL, '2024-06-16'),
('AP-00041', 'Estrada', 'Elena', 'Villanueva', '1992-09-11', 'Unit 7B, 62 Ilang-Ilang Street', 'LC05', 'Santa Elena', NULL, '2024-08-02'),
('AP-00042', 'De Leon', 'Cristina', 'Rosales', '1983-06-12', '54 Kalayaan Avenue', 'LC03', 'Mabini East', NULL, '2024-09-27'),
('AP-00043', 'Ramos', 'Elena', 'Dela Cruz', '1984-01-26', 'Block 13 Lot 4, Ilang-Ilang Street', 'LC02', 'San Isidro Heights', NULL, '2024-06-15'),
('AP-00044', 'Domingo', 'Cristina', 'Navarro', '1969-06-15', 'Unit 7B, 28 Narra Street', 'LC01', 'Luntian Central', NULL, '2024-09-23'),
('AP-00045', 'Ramos', 'Angela', NULL, '1962-08-04', '199 Molave Street', 'LC06', 'Maligaya', NULL, '2024-07-18'),
('AP-00046', 'Alcantara', 'Carlo', 'Ignacio', '1994-08-08', '159 Sampaguita Lane', 'LC02', 'San Isidro Heights', NULL, '2024-10-25'),
('AP-00047', 'Fajardo', 'Liza', 'Alcantara', '1992-07-20', 'Unit 5B, 65 Ilang-Ilang Street', 'LC02', 'San Isidro Heights', NULL, '2024-08-14'),
('AP-00048', 'Aquino', 'Celine', 'Lorenzo', '1987-05-13', 'Block 4 Lot 1, Molave Street', 'LC03', 'Mabini East', NULL, '2024-06-28'),
('AP-00049', 'Ramos', 'Liza', 'Ramos', '1978-12-20', 'Unit 6B, 37 Bamboo Lane', 'LC04', 'Bagong Silangan', NULL, '2024-09-26'),
('AP-00050', 'Cabrera', 'Rafael', 'Ignacio', '1978-05-14', 'Block 14 Lot 25, Acacia Road', 'LC03', 'Mabini East', NULL, '2024-08-21'),
('AP-00051', 'Marquez', 'Ma. Cecilia', 'Lorenzo', '1994-07-15', 'Unit 4B, 53 Ilang-Ilang Street', 'LC02', 'San Isidro Heights', NULL, '2024-06-17'),
('AP-00052', 'Pascual', 'Celine', NULL, '1965-05-03', 'Block 9 Lot 23, Mabini Avenue', 'LC01', 'Luntian Central', NULL, '2024-09-18'),
('AP-00053', 'Santos', 'Antonio', 'Ocampo', '1958-04-25', 'Unit 3B, 54 Sampaguita Lane', 'LC07', 'Pulo Verde', NULL, '2024-07-16'),
('AP-00054', 'Marquez', 'Miguel', 'Valdez', '1995-03-15', 'Block 16 Lot 22, Molave Street', 'LC06', 'Maligaya', NULL, '2024-09-14'),
('AP-00055', 'Lim', 'Cristina', 'Domingo', '1968-06-12', 'Unit 2B, 53 Mabini Avenue', 'LC01', 'Luntian Central', NULL, '2024-08-05'),
('AP-00056', 'Villanueva', 'Angela', 'Lim', '1961-05-17', 'Block 1 Lot 12, Molave Street', 'LC02', 'San Isidro Heights', NULL, '2024-08-10'),
('AP-00057', 'Aquino', 'Enrico', 'Tan', '1959-01-01', 'Block 15 Lot 24, Sampaguita Lane', 'LC03', 'Mabini East', NULL, '2024-08-08'),
('AP-00058', 'Fajardo', 'Lourdes', 'De Leon', '1992-04-23', 'Block 8 Lot 12, Kalayaan Avenue', 'LC03', 'Mabini East', NULL, '2024-08-19'),
('AP-00059', 'Ramos', 'Victor', 'Lorenzo', '1983-05-15', '151 Narra Street', 'LC05', 'Santa Elena', NULL, '2024-10-06'),
('AP-00060', 'Pineda', 'Noel', 'Aguilar', '1986-10-12', '39 Mabini Avenue', 'LC02', 'San Isidro Heights', NULL, '2024-10-26'),
('AP-00061', 'Domingo', 'Joanna', 'Bernardo', '1978-12-04', 'Block 4 Lot 11, Rosal Drive', 'LC02', 'San Isidro Heights', NULL, '2024-07-25'),
('AP-00062', 'Velasco', 'Marielle', 'Flores', '1975-02-19', 'Unit 7B, 64 Ilang-Ilang Street', 'LC02', 'San Isidro Heights', NULL, '2024-06-18'),
('AP-00063', 'Abad', 'Lourdes', 'Dela Cruz', '1976-04-23', 'Block 3 Lot 24, Rosal Drive', 'LC02', 'San Isidro Heights', NULL, '2024-08-31'),
('AP-00064', 'Ocampo', 'Adrian', 'Reyes', '1958-06-12', '130 Ilang-Ilang Street', 'LC07', 'Pulo Verde', NULL, '2024-10-19'),
('AP-00065', 'Rosales', 'Roberto', 'Serrano', '1992-05-11', 'Unit 2B, 61 Rosal Drive', 'LC01', 'Luntian Central', NULL, '2024-06-16'),
('AP-00066', 'Ramos', 'Carlo', 'Velasco', '1999-12-05', 'Block 15 Lot 31, Acacia Road', 'LC04', 'Bagong Silangan', NULL, '2024-09-09'),
('AP-00067', 'Fajardo', 'Gabriel', NULL, '1975-09-16', 'Unit 2B, 28 Rosal Drive', 'LC04', 'Bagong Silangan', NULL, '2024-08-28'),
('AP-00068', 'Ramos', 'Joanna', 'Aquino', '1974-01-05', '146 Narra Street', 'LC02', 'San Isidro Heights', NULL, '2024-09-02'),
('AP-00069', 'Soriano', 'Diana', NULL, '1991-08-17', 'Unit 1B, 77 Acacia Road', 'LC01', 'Luntian Central', NULL, '2024-08-11'),
('AP-00070', 'Fajardo', 'Nathaniel', 'Santos', '1966-05-15', 'Unit 1B, 62 Rosal Drive', 'LC01', 'Luntian Central', NULL, '2024-09-20'),
('AP-00071', 'Flores', 'Joanna', 'Tuazon', '1995-02-18', 'Block 3 Lot 29, Molave Street', 'LC07', 'Pulo Verde', NULL, '2024-08-27'),
('AP-00072', 'Francisco', 'Renato', 'Aguilar', '1989-01-25', 'Unit 7B, 89 Kalayaan Avenue', 'LC08', 'San Rafael Norte', NULL, '2024-10-18'),
('AP-00073', 'Mendoza', 'Isabel', 'Alcantara', '1972-11-27', 'Unit 5B, 57 Molave Street', 'LC04', 'Bagong Silangan', NULL, '2024-08-19'),
('AP-00074', 'Castillo', 'Emilio', 'Villanueva', '1976-12-01', 'Block 5 Lot 10, Rosal Drive', 'LC02', 'San Isidro Heights', NULL, '2024-05-16'),
('AP-00075', 'Dela Cruz', 'Andrea', NULL, '1962-03-08', '124 Sampaguita Lane', 'LC01', 'Luntian Central', NULL, '2024-07-11'),
('AP-00076', 'De Leon', 'Liza', 'Rosales', '1980-12-18', 'Block 1 Lot 7, Narra Street', 'LC06', 'Maligaya', NULL, '2024-06-22'),
('AP-00077', 'Aquino', 'Jose Luis', NULL, '1980-03-11', 'Unit 8B, 61 Talisay Road', 'LC05', 'Santa Elena', NULL, '2024-06-18'),
('AP-00078', 'Marquez', 'Cristina', 'Marquez', '1966-06-03', 'Block 8 Lot 24, Molave Street', 'LC03', 'Mabini East', NULL, '2024-10-12'),
('AP-00079', 'Pascual', 'Eduardo', NULL, '1997-02-02', 'Block 6 Lot 30, Narra Street', 'LC05', 'Santa Elena', NULL, '2024-10-05'),
('AP-00080', 'Alcantara', 'Manuel', 'Flores', '1991-06-15', 'Block 14 Lot 9, Molave Street', 'LC02', 'San Isidro Heights', NULL, '2024-06-11'),
('AP-00081', 'Castillo', 'Patricia', 'Ramos', '1980-08-23', '17 Mabini Avenue', 'LC02', 'San Isidro Heights', NULL, '2024-10-08'),
('AP-00082', 'Marquez', 'Victor', 'Velasco', '1973-04-11', '16 Narra Street', 'LC07', 'Pulo Verde', NULL, '2024-10-09'),
('AP-00083', 'Velasco', 'Nathaniel', NULL, '1999-07-04', '4 Rosal Drive', 'LC08', 'San Rafael Norte', NULL, '2024-09-09'),
('AP-00084', 'Salazar', 'Marco', 'Manalo', '1997-01-10', 'Unit 6B, 34 Sampaguita Lane', 'LC03', 'Mabini East', NULL, '2024-05-26'),
('AP-00085', 'Cabrera', 'Carlo', NULL, '1958-09-17', '224 Kalayaan Avenue', 'LC03', 'Mabini East', NULL, '2024-10-02'),
('AP-00086', 'Abad', 'Rafael', 'Marquez', '1962-02-17', 'Block 1 Lot 14, Narra Street', 'LC02', 'San Isidro Heights', NULL, '2024-06-08'),
('AP-00087', 'Alcantara', 'Bianca', 'Flores', '1976-03-01', 'Unit 1B, 71 Acacia Road', 'LC03', 'Mabini East', NULL, '2024-07-20'),
('AP-00088', 'Velasco', 'Gabriel', NULL, '1977-12-11', 'Block 10 Lot 9, Kalayaan Avenue', 'LC06', 'Maligaya', NULL, '2024-09-04'),
('AP-00089', 'Velasco', 'Elena', 'Velasco', '1963-11-18', '266 Molave Street', 'LC01', 'Luntian Central', NULL, '2024-06-15'),
('AP-00090', 'Pineda', 'Eduardo', 'Francisco', '1997-10-04', '252 Talisay Road', 'LC03', 'Mabini East', NULL, '2024-07-08'),
('AP-00091', 'Pineda', 'Adrian', 'Serrano', '1963-04-08', 'Unit 3B, 86 Sampaguita Lane', 'LC02', 'San Isidro Heights', NULL, '2024-06-25'),
('AP-00092', 'Marquez', 'Manuel', 'Villanueva', '1981-10-10', 'Block 10 Lot 28, Sampaguita Lane', 'LC01', 'Luntian Central', NULL, '2024-09-23'),
('AP-00093', 'Serrano', 'Liza', 'Valdez', '1976-01-07', 'Block 7 Lot 11, Rosal Drive', 'LC04', 'Bagong Silangan', NULL, '2024-10-10'),
('AP-00094', 'Villanueva', 'Gabriel', 'Alcantara', '1999-04-04', 'Block 7 Lot 32, Rosal Drive', 'LC03', 'Mabini East', NULL, '2024-10-23'),
('AP-00095', 'Serrano', 'Janelle', 'Rosales', '1987-02-18', 'Block 5 Lot 26, Kalayaan Avenue', 'LC03', 'Mabini East', NULL, '2024-09-17'),
('AP-00096', 'Tolentino', 'Paolo', 'Velasco', '1966-07-22', '167 Mabini Avenue', 'LC06', 'Maligaya', NULL, '2024-08-19'),
('AP-00097', 'Serrano', 'Rosario', 'Salazar', '1982-03-19', 'Unit 3B, 32 Molave Street', 'LC05', 'Santa Elena', NULL, '2024-07-14'),
('AP-00098', 'Pascual', 'Grace', NULL, '1980-07-17', 'Block 15 Lot 32, Talisay Road', 'LC02', 'San Isidro Heights', NULL, '2024-08-25'),
('AP-00099', 'Serrano', 'Rosario', 'Serrano', '1967-03-08', '162 Kalayaan Avenue', 'LC03', 'Mabini East', NULL, '2024-09-25'),
('AP-00100', 'Soriano', 'Carlo', 'Aquino', '1991-08-25', '253 Acacia Road', 'LC04', 'Bagong Silangan', NULL, '2024-06-25'),
('AP-00101', 'Castillo', 'Janelle', 'Villanueva', '1999-11-24', 'Block 13 Lot 16, Sampaguita Lane', 'LC08', 'San Rafael Norte', NULL, '2024-09-20'),
('AP-00102', 'Reyes', 'Adrian', 'Abad', '1994-05-12', 'Unit 6B, 84 Bamboo Lane', 'LC03', 'Mabini East', NULL, '2024-07-05'),
('AP-00103', 'Bautista', 'Camille', 'Abad', '1981-01-15', 'Block 11 Lot 27, Narra Street', 'LC07', 'Pulo Verde', NULL, '2024-07-13'),
('AP-00104', 'Manalo', 'Angela', 'Garcia', '1974-01-13', '95 Kalayaan Avenue', 'LC03', 'Mabini East', NULL, '2024-10-12'),
('AP-00105', 'Mercado', 'Alfredo', 'Tuazon', '1964-03-05', 'Block 3 Lot 24, Acacia Road', 'LC04', 'Bagong Silangan', NULL, '2024-10-12'),
('AP-00106', 'Alcantara', 'Janelle', 'Garcia', '1972-11-20', '188 Ilang-Ilang Street', 'LC05', 'Santa Elena', NULL, '2024-08-04'),
('AP-00107', 'De Leon', 'Elena', 'Alcantara', '1998-09-15', '110 Sampaguita Lane', 'LC06', 'Maligaya', NULL, '2024-07-26'),
('AP-00108', 'Pascual', 'Paolo', 'Ignacio', '1958-08-06', '256 Rosal Drive', 'LC02', 'San Isidro Heights', NULL, '2024-07-12'),
('AP-00109', 'Domingo', 'Elena', 'De Leon', '1979-04-09', '211 Narra Street', 'LC03', 'Mabini East', NULL, '2024-07-10'),
('AP-00110', 'Soriano', 'Patricia', 'Domingo', '1969-03-10', 'Unit 5B, 21 Sampaguita Lane', 'LC04', 'Bagong Silangan', NULL, '2024-07-04'),
('AP-00111', 'Fajardo', 'Isabel', NULL, '1975-08-24', 'Block 2 Lot 27, Sampaguita Lane', 'LC05', 'Santa Elena', NULL, '2024-08-02'),
('AP-00112', 'Ocampo', 'Jose Luis', 'Alcantara', '1957-08-06', 'Unit 2B, 73 Ilang-Ilang Street', 'LC07', 'Pulo Verde', NULL, '2024-09-14'),
('AP-00113', 'Pineda', 'Carlo', 'Valdez', '1998-12-25', '179 Sampaguita Lane', 'LC03', 'Mabini East', NULL, '2024-09-03'),
('AP-00114', 'Pineda', 'Grace', NULL, '1988-09-16', 'Block 7 Lot 1, Bamboo Lane', 'LC01', 'Luntian Central', NULL, '2024-09-10'),
('AP-00115', 'Fajardo', 'Grace', 'Marquez', '1966-02-28', '70 Mabini Avenue', 'LC02', 'San Isidro Heights', NULL, '2024-08-03'),
('AP-00116', 'Dela Cruz', 'Emilio', 'Serrano', '1992-06-11', 'Block 9 Lot 26, Talisay Road', 'LC04', 'Bagong Silangan', NULL, '2024-10-23'),
('AP-00117', 'Marquez', 'Alfredo', 'Mercado', '1977-11-23', 'Unit 4B, 41 Bamboo Lane', 'LC04', 'Bagong Silangan', NULL, '2024-07-21'),
('AP-00118', 'Estrada', 'Liza', 'De Leon', '1977-11-21', '178 Narra Street', 'LC01', 'Luntian Central', NULL, '2024-09-12'),
('AP-00119', 'Mercado', 'Roberto', 'Lim', '1975-10-06', 'Unit 8B, 46 Ilang-Ilang Street', 'LC01', 'Luntian Central', NULL, '2024-05-20'),
('AP-00120', 'Ignacio', 'Cristina', 'Aguilar', '1999-06-07', '171 Bamboo Lane', 'LC02', 'San Isidro Heights', NULL, '2024-10-21'),
('AP-00121', 'Castillo', 'Marco', 'Estrada', '1998-10-22', 'Block 4 Lot 24, Molave Street', 'LC02', 'San Isidro Heights', NULL, '2024-09-12'),
('AP-00122', 'Valdez', 'Andrea', 'Salazar', '1975-12-09', 'Block 15 Lot 18, Acacia Road', 'LC03', 'Mabini East', NULL, '2024-07-23'),
('AP-00123', 'Lim', 'Nathaniel', 'Salazar', '1960-01-15', '148 Molave Street', 'LC01', 'Luntian Central', NULL, '2024-10-01'),
('AP-00124', 'Abad', 'Joanna', NULL, '1965-03-13', 'Unit 4B, 87 Acacia Road', 'LC06', 'Maligaya', NULL, '2024-09-22'),
('AP-00125', 'Pascual', 'Theresa', 'Villanueva', '1999-09-08', 'Unit 6B, 25 Molave Street', 'LC04', 'Bagong Silangan', NULL, '2024-10-19'),
('AP-00126', 'Rosales', 'Paolo', 'Cabrera', '1974-01-14', 'Block 16 Lot 32, Rosal Drive', 'LC05', 'Santa Elena', NULL, '2024-07-12'),
('AP-00127', 'Flores', 'Celine', 'Salazar', '1958-10-10', 'Unit 7B, 53 Ilang-Ilang Street', 'LC01', 'Luntian Central', NULL, '2024-10-10'),
('AP-00128', 'Reyes', 'Patricia', 'Flores', '1990-04-26', 'Block 10 Lot 18, Rosal Drive', 'LC01', 'Luntian Central', NULL, '2024-06-15'),
('AP-00129', 'Santos', 'Camille', 'Manalo', '1961-06-17', 'Block 15 Lot 23, Narra Street', 'LC01', 'Luntian Central', NULL, '2024-06-25'),
('AP-00130', 'Velasco', 'Angela', 'Francisco', '1996-11-08', '30 Rosal Drive', 'LC02', 'San Isidro Heights', NULL, '2024-07-30'),
('AP-00131', 'Soriano', 'Eduardo', 'Ignacio', '1980-10-04', '85 Mabini Avenue', 'LC05', 'Santa Elena', NULL, '2024-07-24'),
('AP-00132', 'Fajardo', 'Andrea', 'Lim', '1972-05-18', '227 Sampaguita Lane', 'LC02', 'San Isidro Heights', NULL, '2024-05-17'),
('AP-00133', 'Bautista', 'Marielle', 'Fajardo', '1978-05-20', 'Unit 1B, 77 Kalayaan Avenue', 'LC08', 'San Rafael Norte', NULL, '2024-05-12'),
('AP-00134', 'Ocampo', 'Theresa', 'Castillo', '1988-06-10', 'Block 7 Lot 30, Ilang-Ilang Street', 'LC07', 'Pulo Verde', NULL, '2024-05-07'),
('AP-00135', 'Salazar', 'Grace', 'Tuazon', '1977-12-21', 'Block 6 Lot 30, Kalayaan Avenue', 'LC01', 'Luntian Central', NULL, '2024-07-05'),
('AP-00136', 'Tolentino', 'Celine', NULL, '1998-02-01', 'Block 4 Lot 20, Bamboo Lane', 'LC02', 'San Isidro Heights', NULL, '2024-06-24'),
('AP-00137', 'Lim', 'Francis', 'Manalo', '1957-12-19', 'Block 15 Lot 29, Sampaguita Lane', 'LC03', 'Mabini East', NULL, '2024-09-14'),
('AP-00138', 'Soriano', 'Theresa', 'Mendoza', '1967-07-27', '260 Rosal Drive', 'LC01', 'Luntian Central', NULL, '2024-10-16'),
('AP-00139', 'Cabrera', 'Eduardo', 'Salazar', '1976-08-21', 'Unit 8B, 24 Rosal Drive', 'LC04', 'Bagong Silangan', NULL, '2024-06-29'),
('AP-00140', 'Villanueva', 'Marielle', 'Tuazon', '1980-10-15', 'Unit 7B, 29 Sampaguita Lane', 'LC01', 'Luntian Central', NULL, '2024-06-03'),
('AP-00141', 'Ignacio', 'Noel', 'Ocampo', '1988-12-05', 'Unit 5B, 19 Rosal Drive', 'LC02', 'San Isidro Heights', NULL, '2024-08-29'),
('AP-00142', 'Cabrera', 'Eduardo', 'Pineda', '1996-04-08', 'Block 4 Lot 7, Sampaguita Lane', 'LC07', 'Pulo Verde', NULL, '2024-09-11'),
('AP-00143', 'Reyes', 'Rafael', 'Ignacio', '1971-09-27', 'Block 16 Lot 5, Sampaguita Lane', 'LC01', 'Luntian Central', NULL, '2024-08-23'),
('AP-00144', 'Velasco', 'Eduardo', 'Cabrera', '1982-10-09', '256 Ilang-Ilang Street', 'LC02', 'San Isidro Heights', NULL, '2024-08-27'),
('AP-00145', 'Cabrera', 'Carlo', 'Pineda', '1980-04-10', 'Unit 8B, 24 Acacia Road', 'LC04', 'Bagong Silangan', NULL, '2024-06-24'),
('AP-00146', 'Bernardo', 'Roberto', 'Ocampo', '1964-07-09', 'Block 9 Lot 28, Kalayaan Avenue', 'LC01', 'Luntian Central', NULL, '2024-05-19'),
('AP-00147', 'Lorenzo', 'Nathaniel', NULL, '1990-04-01', 'Unit 3B, 43 Molave Street', 'LC03', 'Mabini East', NULL, '2024-08-25'),
('AP-00148', 'Aguilar', 'Danica', 'Cabrera', '1987-11-21', '166 Bamboo Lane', 'LC06', 'Maligaya', NULL, '2024-08-01'),
('AP-00149', 'Reyes', 'Jose Luis', 'Mendoza', '1994-04-16', 'Block 7 Lot 21, Molave Street', 'LC01', 'Luntian Central', NULL, '2024-08-28'),
('AP-00150', 'Pineda', 'Miguel', 'Tuazon', '1971-03-15', 'Block 5 Lot 1, Narra Street', 'LC04', 'Bagong Silangan', NULL, '2024-08-11'),
('AP-00151', 'Bautista', 'Andrea', NULL, '1982-03-28', '10 Acacia Road', 'LC06', 'Maligaya', NULL, '2024-10-25'),
('AP-00152', 'Flores', 'Marielle', 'Abad', '1986-08-02', 'Unit 6B, 45 Narra Street', 'LC07', 'Pulo Verde', NULL, '2024-10-21'),
('AP-00153', 'Lorenzo', 'Miguel', 'Villanueva', '1998-03-22', 'Unit 1B, 29 Molave Street', 'LC06', 'Maligaya', NULL, '2024-10-19'),
('AP-00154', 'Ramos', 'Paolo', 'Estrada', '1989-10-10', '25 Molave Street', 'LC01', 'Luntian Central', NULL, '2024-09-23'),
('AP-00155', 'Ramos', 'Andrea', 'Aquino', '2000-01-27', 'Unit 2B, 90 Acacia Road', 'LC01', 'Luntian Central', NULL, '2024-05-15'),
('AP-00156', 'Alcantara', 'Francis', 'De Leon', '1993-07-08', 'Unit 4B, 80 Narra Street', 'LC06', 'Maligaya', NULL, '2024-10-27'),
('AP-00157', 'Aquino', 'Patricia', 'Bernardo', '1997-03-09', '133 Molave Street', 'LC03', 'Mabini East', NULL, '2024-07-29'),
('AP-00158', 'Dela Cruz', 'Lourdes', 'Navarro', '1983-05-07', '185 Sampaguita Lane', 'LC05', 'Santa Elena', NULL, '2024-10-16'),
('AP-00159', 'Domingo', 'Noel', 'Navarro', '1964-05-28', 'Block 6 Lot 15, Ilang-Ilang Street', 'LC04', 'Bagong Silangan', NULL, '2024-08-04'),
('AP-00160', 'Aquino', 'Manuel', 'Soriano', '1981-06-05', '49 Bamboo Lane', 'LC01', 'Luntian Central', NULL, '2024-09-27'),
('AP-00161', 'Manalo', 'Carlo', 'Navarro', '1978-03-18', 'Block 4 Lot 1, Narra Street', 'LC01', 'Luntian Central', NULL, '2024-09-21'),
('AP-00162', 'Ramos', 'Celine', 'Cabrera', '1983-04-11', 'Unit 7B, 45 Ilang-Ilang Street', 'LC01', 'Luntian Central', NULL, '2024-08-07'),
('AP-00163', 'Salazar', 'Elena', 'Reyes', '1958-06-25', '150 Ilang-Ilang Street', 'LC01', 'Luntian Central', NULL, '2024-08-21'),
('AP-00164', 'Reyes', 'Cristina', 'Estrada', '1969-07-09', '54 Acacia Road', 'LC03', 'Mabini East', NULL, '2024-07-10'),
('AP-00165', 'Mendoza', 'Patricia', 'Tuazon', '1998-03-22', '216 Narra Street', 'LC07', 'Pulo Verde', NULL, '2024-06-21'),
('AP-00166', 'Ramos', 'Francis', 'Bautista', '1964-01-15', '176 Acacia Road', 'LC05', 'Santa Elena', NULL, '2024-07-17'),
('AP-00167', 'Mendoza', 'Liza', 'Domingo', '1973-02-19', 'Block 2 Lot 18, Ilang-Ilang Street', 'LC01', 'Luntian Central', NULL, '2024-06-08'),
('AP-00168', 'Fajardo', 'Roberto', 'Soriano', '1973-02-26', 'Unit 4B, 69 Bamboo Lane', 'LC01', 'Luntian Central', NULL, '2024-06-01'),
('AP-00169', 'Lim', 'Carlo', 'Dela Cruz', '1970-09-20', 'Block 14 Lot 17, Sampaguita Lane', 'LC03', 'Mabini East', NULL, '2024-05-25'),
('AP-00170', 'Ramos', 'Lourdes', 'Lorenzo', '1992-08-15', '141 Rosal Drive', 'LC03', 'Mabini East', NULL, '2024-08-24'),
('AP-00171', 'Francisco', 'Janelle', 'Aguilar', '1973-06-28', '150 Talisay Road', 'LC01', 'Luntian Central', NULL, '2024-06-10'),
('AP-00172', 'Francisco', 'Eduardo', 'Pascual', '1990-04-05', 'Unit 7B, 28 Molave Street', 'LC06', 'Maligaya', NULL, '2024-10-19'),
('AP-00173', 'Tolentino', 'Nathaniel', 'Dela Cruz', '1958-09-21', '40 Narra Street', 'LC01', 'Luntian Central', NULL, '2024-05-20'),
('AP-00174', 'Serrano', 'Adrian', 'Bernardo', '1973-12-14', 'Unit 7B, 21 Rosal Drive', 'LC03', 'Mabini East', NULL, '2024-07-11'),
('AP-00175', 'Manalo', 'Emilio', 'Valdez', '1976-06-22', 'Unit 5B, 28 Ilang-Ilang Street', 'LC01', 'Luntian Central', NULL, '2024-06-17'),
('AP-00176', 'Estrada', 'Eduardo', 'Aquino', '1958-05-20', 'Block 6 Lot 10, Sampaguita Lane', 'LC04', 'Bagong Silangan', NULL, '2024-10-26'),
('AP-00177', 'Salazar', 'Celine', 'Ignacio', '1974-07-28', '159 Mabini Avenue', 'LC05', 'Santa Elena', NULL, '2024-09-23'),
('AP-00178', 'Ramos', 'Rosario', 'Cabrera', '1963-12-20', 'Unit 4B, 30 Narra Street', 'LC02', 'San Isidro Heights', NULL, '2024-06-09'),
('AP-00179', 'Garcia', 'Eduardo', 'Lorenzo', '1982-01-09', 'Unit 4B, 89 Molave Street', 'LC02', 'San Isidro Heights', NULL, '2024-10-21'),
('AP-00180', 'Villanueva', 'Roberto', NULL, '1962-08-27', 'Unit 8B, 49 Molave Street', 'LC07', 'Pulo Verde', NULL, '2024-10-05'),
('AP-00181', 'Fajardo', 'Janelle', 'Salazar', '2000-10-25', '69 Kalayaan Avenue', 'LC07', 'Pulo Verde', NULL, '2024-09-01'),
('AP-00182', 'Bernardo', 'Enrico', 'Rosales', '1969-11-24', '53 Ilang-Ilang Street', 'LC06', 'Maligaya', NULL, '2024-09-22'),
('AP-00183', 'Fajardo', 'Roberto', 'Santos', '1978-01-26', '48 Talisay Road', 'LC06', 'Maligaya', NULL, '2024-09-29'),
('AP-00184', 'Soriano', 'Francis', 'Estrada', '1969-12-16', '213 Talisay Road', 'LC04', 'Bagong Silangan', NULL, '2024-10-25'),
('AP-00185', 'Rosales', 'Ma. Cecilia', 'Navarro', '1997-12-03', 'Unit 7B, 66 Acacia Road', 'LC03', 'Mabini East', NULL, '2024-06-10'),
('AP-00186', 'Mendoza', 'Eduardo', 'Garcia', '1989-12-08', 'Unit 3B, 74 Molave Street', 'LC04', 'Bagong Silangan', NULL, '2024-07-14'),
('AP-00187', 'Garcia', 'Isabel', NULL, '1961-08-04', 'Block 7 Lot 22, Sampaguita Lane', 'LC06', 'Maligaya', NULL, '2024-06-09'),
('AP-00188', 'Ignacio', 'Angela', 'Tan', '1962-02-05', 'Block 14 Lot 12, Mabini Avenue', 'LC04', 'Bagong Silangan', NULL, '2024-10-16'),
('AP-00189', 'Lorenzo', 'Bianca', NULL, '1999-08-07', 'Block 4 Lot 22, Talisay Road', 'LC04', 'Bagong Silangan', NULL, '2024-08-15'),
('AP-00190', 'Velasco', 'Grace', 'Manalo', '1983-02-16', 'Block 8 Lot 19, Kalayaan Avenue', 'LC02', 'San Isidro Heights', NULL, '2024-09-22'),
('AP-00191', 'Pineda', 'Danica', 'De Leon', '1976-05-24', '48 Ilang-Ilang Street', 'LC07', 'Pulo Verde', NULL, '2024-09-21'),
('AP-00192', 'Serrano', 'Lourdes', 'Ramos', '1984-04-17', 'Unit 6B, 22 Ilang-Ilang Street', 'LC05', 'Santa Elena', NULL, '2024-06-09'),
('AP-00193', 'Garcia', 'Antonio', 'Abad', '1968-12-18', 'Unit 3B, 82 Kalayaan Avenue', 'LC01', 'Luntian Central', NULL, '2024-08-06'),
('AP-00194', 'Francisco', 'Lourdes', 'Tan', '1968-06-23', 'Block 8 Lot 10, Acacia Road', 'LC02', 'San Isidro Heights', NULL, '2024-06-12'),
('AP-00195', 'Mercado', 'Carlo', 'Mercado', '1985-10-08', 'Unit 4B, 47 Talisay Road', 'LC02', 'San Isidro Heights', NULL, '2024-09-19'),
('AP-00196', 'Tuazon', 'Eduardo', 'Serrano', '1962-11-12', '215 Ilang-Ilang Street', 'LC04', 'Bagong Silangan', NULL, '2024-06-04'),
('AP-00197', 'Francisco', 'Noel', 'Lorenzo', '1974-09-09', 'Block 3 Lot 19, Ilang-Ilang Street', 'LC03', 'Mabini East', NULL, '2024-08-09'),
('AP-00198', 'Francisco', 'Adrian', 'Marquez', '1996-04-15', '244 Mabini Avenue', 'LC04', 'Bagong Silangan', NULL, '2024-08-24'),
('AP-00199', 'Marquez', 'Jose Luis', 'Dela Cruz', '1977-05-27', 'Block 16 Lot 5, Kalayaan Avenue', 'LC02', 'San Isidro Heights', NULL, '2024-07-07'),
('AP-00200', 'Estrada', 'Bianca', 'Navarro', '1974-04-06', '42 Narra Street', 'LC03', 'Mabini East', NULL, '2024-09-17'),
('AP-00201', 'Fajardo', 'Diana', 'Tolentino', '1995-01-04', 'Block 9 Lot 5, Narra Street', 'LC07', 'Pulo Verde', NULL, '2024-07-25'),
('AP-00202', 'Bautista', 'Antonio', 'Manalo', '1960-05-27', 'Block 13 Lot 26, Acacia Road', 'LC05', 'Santa Elena', NULL, '2024-07-04'),
('AP-00203', 'Lorenzo', 'Janelle', 'Manalo', '1985-09-25', 'Block 4 Lot 15, Rosal Drive', 'LC03', 'Mabini East', NULL, '2024-07-24'),
('AP-00204', 'Domingo', 'Bianca', 'Domingo', '1999-01-19', 'Unit 8B, 22 Narra Street', 'LC03', 'Mabini East', NULL, '2024-09-29'),
('AP-00205', 'Flores', 'Francis', 'Alcantara', '1978-03-21', '29 Talisay Road', 'LC06', 'Maligaya', NULL, '2024-07-18'),
('AP-00206', 'Castillo', 'Isabel', 'Lorenzo', '1989-02-04', 'Block 10 Lot 28, Mabini Avenue', 'LC02', 'San Isidro Heights', NULL, '2024-07-03'),
('AP-00207', 'Bautista', 'Marco', NULL, '1996-09-23', '13 Rosal Drive', 'LC07', 'Pulo Verde', NULL, '2024-05-30'),
('AP-00208', 'Reyes', 'Diana', 'Santos', '1997-06-17', 'Unit 6B, 34 Ilang-Ilang Street', 'LC06', 'Maligaya', NULL, '2024-06-16'),
('AP-00209', 'Manalo', 'Marco', 'Aquino', '1994-05-27', 'Block 10 Lot 19, Molave Street', 'LC01', 'Luntian Central', NULL, '2024-07-22'),
('AP-00210', 'Villanueva', 'Angela', 'Valdez', '1970-09-08', 'Unit 1B, 57 Sampaguita Lane', 'LC02', 'San Isidro Heights', NULL, '2024-08-25');

INSERT INTO firearms (gun_no, serialno, maker, model, guntype, regref, recdate) VALUES
('GF-00001', 'BY1147A', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-224005', '2024-09-27'),
('GF-00002', '9479777', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-950825', '2024-08-05'),
('GF-00003', 'SL4462A', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-353781', '2024-05-25'),
('GF-00004', '5933604', 'Crestline Works', 'CW-Special', 'Other', 'REG-749167', '2024-04-30'),
('GF-00005', '47-79648', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-870558', '2024-05-11'),
('GF-00006', '2753914', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-452200', '2024-07-05'),
('GF-00007', 'PC6363D', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-807681', '2024-08-06'),
('GF-00008', 'PC7567D', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-747370', '2024-07-19'),
('GF-00009', 'M684443', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-168660', '2024-06-23'),
('GF-00010', '6452672', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-735035', '2024-05-21'),
('GF-00011', 'BY2786D', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-150412', '2024-08-02'),
('GF-00012', '2488043', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-178532', '2024-09-18'),
('GF-00013', 'PC3671A', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-820453', '2024-06-13'),
('GF-00014', 'E241037', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-753045', '2024-04-18'),
('GF-00015', 'C824856', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-526640', '2024-06-17'),
('GF-00016', '37-18780', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-768636', '2024-08-19'),
('GF-00017', 'AM7084D', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-539192', '2024-09-20'),
('GF-00018', 'A211617', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-459477', '2024-04-13'),
('GF-00019', '2676054', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-298018', '2024-06-25'),
('GF-00020', '9996458', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-545467', '2024-07-31'),
('GF-00021', '9269068', 'Maharlika Fabrication', 'MF-Service', 'Handgun', NULL, '2024-07-25'),
('GF-00022', '2893785', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-809128', '2024-07-22'),
('GF-00023', '16-75763', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-720775', '2024-06-18'),
('GF-00024', 'AM3105A', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-555989', '2024-08-21'),
('GF-00025', '2574531', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-959877', '2024-05-13'),
('GF-00026', 'AM9057D', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-845072', '2024-08-02'),
('GF-00027', 'SL1773A', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-884535', '2024-09-28'),
('GF-00028', '1886966', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-972947', '2024-10-03'),
('GF-00029', 'E852881', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-526962', '2024-05-20'),
('GF-00030', '93-52491', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-564747', '2024-10-08'),
('GF-00031', '9031562', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-965142', '2024-10-13'),
('GF-00032', '25-38572', 'Amihan Works', 'AW-Compact', 'Handgun', NULL, '2024-06-03'),
('GF-00033', 'F696730', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-615392', '2024-04-02'),
('GF-00034', 'AM8054A', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-427248', '2024-07-09'),
('GF-00035', '5619754', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-524274', '2024-05-29'),
('GF-00036', '13-61968', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-584052', '2024-07-10'),
('GF-00037', '71-88316', 'Silangan Precision', 'SP-Field', 'Rifle', NULL, '2024-06-10'),
('GF-00038', 'SL2923D', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-492294', '2024-06-12'),
('GF-00039', '61-33189', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-534359', '2024-06-16'),
('GF-00040', '59-21079', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-940119', '2024-06-09'),
('GF-00041', 'A951089', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-913399', '2024-05-12'),
('GF-00042', '5560344', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-231526', '2024-06-16'),
('GF-00043', 'N449836', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-484823', '2024-09-05'),
('GF-00044', '9331537', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-614993', '2024-08-27'),
('GF-00045', '24-70314', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-616393', '2024-05-17'),
('GF-00046', '78-82153', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-560997', '2024-05-31'),
('GF-00047', '2459297', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-373988', '2024-09-21'),
('GF-00048', '3388511', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-170599', '2024-07-13'),
('GF-00049', '39-36670', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-738283', '2024-07-13'),
('GF-00050', '68-79425', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-825661', '2024-08-09'),
('GF-00051', 'L204381', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', NULL, '2024-07-16'),
('GF-00052', '9589292', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-242666', '2024-07-20'),
('GF-00053', '97-22921', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-676681', '2024-07-25'),
('GF-00054', '9289879', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-421193', '2024-06-26'),
('GF-00055', '9282755', 'Crestline Works', 'CW-Special', 'Other', 'REG-178279', '2024-09-23'),
('GF-00056', 'M446172', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-801458', '2024-04-29'),
('GF-00057', 'PC7986A', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-601834', '2024-09-07'),
('GF-00058', '81-94744', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-263349', '2024-05-11'),
('GF-00059', '2163537', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-235824', '2024-05-29'),
('GF-00060', 'L161212', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-937830', '2024-05-16'),
('GF-00061', '19-50001', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-971098', '2024-07-24'),
('GF-00062', 'K996365', 'Bayani Arms', 'BA-Sport', 'Shotgun', NULL, '2024-10-24'),
('GF-00063', 'M396220', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-131871', '2024-09-16'),
('GF-00064', '4597471', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-695376', '2024-06-17'),
('GF-00065', '27-61361', 'Crestline Works', 'CW-Special', 'Other', NULL, '2024-10-22'),
('GF-00066', '8112305', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-478044', '2024-05-11'),
('GF-00067', 'A121060', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-120228', '2024-04-29'),
('GF-00068', '30-63082', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-275269', '2024-09-13'),
('GF-00069', 'AM3652B', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-366986', '2024-05-19'),
('GF-00070', 'BY1241C', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-189533', '2024-05-31'),
('GF-00071', 'F990363', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-188097', '2024-09-23'),
('GF-00072', '4255458', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-432613', '2024-05-26'),
('GF-00073', 'BY7099A', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-597579', '2024-08-31'),
('GF-00074', 'L624026', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-756169', '2024-10-18'),
('GF-00075', 'PC4967A', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-194592', '2024-10-10'),
('GF-00076', '4748076', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-466741', '2024-06-04'),
('GF-00077', 'MH1616C', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-325358', '2024-08-29'),
('GF-00078', '30-66305', 'Harbor Engineering', 'HE-Compact', 'Handgun', NULL, '2024-09-23'),
('GF-00079', 'PC3105A', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-612602', '2024-09-19'),
('GF-00080', 'SL4130D', 'Amihan Works', 'AW-Compact', 'Handgun', NULL, '2024-10-19'),
('GF-00081', 'G936941', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-420333', '2024-06-29'),
('GF-00082', 'E758849', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-129345', '2024-06-29'),
('GF-00083', '6721299', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-373933', '2024-10-01'),
('GF-00084', 'G938536', 'Crestline Works', 'CW-Special', 'Other', 'REG-591086', '2024-08-17'),
('GF-00085', '3537992', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-652489', '2024-05-29'),
('GF-00086', 'SL7945A', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-849629', '2024-05-12'),
('GF-00087', 'B845088', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-245375', '2024-06-11'),
('GF-00088', 'BY2810A', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-953342', '2024-04-30'),
('GF-00089', '83-83778', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-919891', '2024-08-11'),
('GF-00090', '58-15979', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-840730', '2024-10-11'),
('GF-00091', 'B683823', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-195513', '2024-08-10'),
('GF-00092', '7198713', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-109663', '2024-09-21'),
('GF-00093', '2121646', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-210333', '2024-06-05'),
('GF-00094', 'A995824', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-107675', '2024-06-08'),
('GF-00095', 'H978796', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-640929', '2024-04-02'),
('GF-00096', '5402055', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-883969', '2024-05-17'),
('GF-00097', '7115113', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-828813', '2024-07-23'),
('GF-00098', '6322004', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-220161', '2024-09-01'),
('GF-00099', '2388394', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-115989', '2024-09-23'),
('GF-00100', '6134912', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-343992', '2024-04-27'),
('GF-00101', '95-11344', 'Amihan Works', 'AW-Compact', 'Handgun', NULL, '2024-06-05'),
('GF-00102', 'SL6895B', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-300489', '2024-08-01'),
('GF-00103', 'SL9711D', 'Crestline Works', 'CW-Special', 'Other', 'REG-780780', '2024-05-26'),
('GF-00104', '6482219', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-304784', '2024-10-08'),
('GF-00105', 'C754046', 'Crestline Works', 'CW-Special', 'Other', 'REG-460054', '2024-05-14'),
('GF-00106', '81-13038', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-947775', '2024-10-12'),
('GF-00107', '1722131', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-366726', '2024-07-16'),
('GF-00108', '8279070', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-210976', '2024-06-11'),
('GF-00109', '57-47693', 'Maharlika Fabrication', 'MF-Service', 'Handgun', NULL, '2024-07-11'),
('GF-00110', '3445696', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-259804', '2024-04-15'),
('GF-00111', '4957868', 'Harbor Engineering', 'HE-Compact', 'Handgun', NULL, '2024-10-16'),
('GF-00112', 'SL4811A', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-946289', '2024-08-23'),
('GF-00113', '35-42202', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-134429', '2024-09-30'),
('GF-00114', 'AM6848B', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-717997', '2024-10-16'),
('GF-00115', 'MH7688B', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-930645', '2024-10-14'),
('GF-00116', '9487914', 'Silangan Precision', 'SP-Field', 'Rifle', NULL, '2024-04-18'),
('GF-00117', 'N188524', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-922256', '2024-06-21'),
('GF-00118', '59-20761', 'Crestline Works', 'CW-Special', 'Other', 'REG-461827', '2024-04-16'),
('GF-00119', '50-14461', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-208217', '2024-08-22'),
('GF-00120', '75-48327', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-308212', '2024-05-15'),
('GF-00121', '3710596', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-521559', '2024-03-26'),
('GF-00122', 'AM8714B', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-383447', '2024-09-18'),
('GF-00123', '6077708', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-141406', '2024-05-18'),
('GF-00124', '6393108', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-862556', '2024-10-19'),
('GF-00125', '4495219', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-633524', '2024-05-27'),
('GF-00126', 'BY2475C', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-493959', '2024-10-23'),
('GF-00127', '1344170', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-684981', '2024-09-15'),
('GF-00128', 'D504211', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-588414', '2024-07-24'),
('GF-00129', 'G214672', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-865493', '2024-07-14'),
('GF-00130', 'SL4468A', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-611918', '2024-04-04'),
('GF-00131', '77-92482', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-163713', '2024-05-18'),
('GF-00132', 'K736909', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-786798', '2024-03-27'),
('GF-00133', '5657618', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-829741', '2024-07-05'),
('GF-00134', '4871584', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-544420', '2024-08-18'),
('GF-00135', '8744543', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-300979', '2024-06-06'),
('GF-00136', '8646514', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-661284', '2024-05-02'),
('GF-00137', 'J130054', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-406637', '2024-10-09'),
('GF-00138', 'PC8267A', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-383053', '2024-07-05'),
('GF-00139', '6761563', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-726334', '2024-05-30'),
('GF-00140', 'E317390', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-380455', '2024-09-04'),
('GF-00141', '2526303', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-575159', '2024-06-01'),
('GF-00142', '62-51625', 'Bayani Arms', 'BA-Sport', 'Shotgun', NULL, '2024-05-27'),
('GF-00143', 'K712912', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-567685', '2024-05-15'),
('GF-00144', '76-38869', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-634834', '2024-07-18'),
('GF-00145', 'D860727', 'Maharlika Fabrication', 'MF-Service', 'Handgun', NULL, '2024-04-09'),
('GF-00146', '5814268', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-924698', '2024-04-18'),
('GF-00147', '6150876', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-764412', '2024-09-12'),
('GF-00148', 'H136427', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-236935', '2024-09-07'),
('GF-00149', 'PC2283A', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-654446', '2024-08-16'),
('GF-00150', 'BY7414A', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-803330', '2024-06-29'),
('GF-00151', 'E794808', 'Amihan Works', 'AW-Compact', 'Handgun', NULL, '2024-07-02'),
('GF-00152', 'J579275', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-114556', '2024-05-11'),
('GF-00153', 'BY5666D', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-107193', '2024-08-23'),
('GF-00154', 'C833743', 'Bayani Arms', 'BA-Sport', 'Shotgun', NULL, '2024-10-21'),
('GF-00155', 'SL1602A', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-167814', '2024-04-08'),
('GF-00156', 'M609062', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-692460', '2024-09-27'),
('GF-00157', '6951591', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-443433', '2024-08-10'),
('GF-00158', 'BY8392B', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-688938', '2024-10-19'),
('GF-00159', '37-11556', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-785024', '2024-09-17'),
('GF-00160', 'B145585', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-371468', '2024-08-18'),
('GF-00161', 'C803664', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-573102', '2024-04-30'),
('GF-00162', '7146264', 'Sierra Metalworks', 'SM-Utility', 'Shotgun', 'REG-437981', '2024-05-19'),
('GF-00163', 'A309290', 'Pacific Crest', 'PC-Classic', 'Rifle', NULL, '2024-05-16'),
('GF-00164', '21-98846', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-669649', '2024-08-07'),
('GF-00165', 'M469317', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-212252', '2024-04-24'),
('GF-00166', 'MH9279A', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-238174', '2024-06-03'),
('GF-00167', '9408751', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-374360', '2024-08-20'),
('GF-00168', 'D944255', 'Bayani Arms', 'BA-Sport', 'Shotgun', 'REG-634339', '2024-10-13'),
('GF-00169', 'SL2835D', 'Crestline Works', 'CW-Special', 'Other', 'REG-590288', '2024-10-26'),
('GF-00170', '5583702', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-731150', '2024-07-04'),
('GF-00171', '9254383', 'Silangan Precision', 'SP-Field', 'Rifle', NULL, '2024-04-18'),
('GF-00172', '13-15864', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-689983', '2024-09-10'),
('GF-00173', 'B707799', 'Crestline Works', 'CW-Special', 'Other', 'REG-715594', '2024-04-10'),
('GF-00174', 'PC3336C', 'Maharlika Fabrication', 'MF-Service', 'Handgun', NULL, '2024-06-04'),
('GF-00175', '2582454', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-996722', '2024-07-17'),
('GF-00176', 'BY4071A', 'Maharlika Fabrication', 'MF-Service', 'Handgun', NULL, '2024-06-29'),
('GF-00177', 'G581833', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-706287', '2024-10-16'),
('GF-00178', 'D635650', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-714654', '2024-06-19'),
('GF-00179', 'MH2771A', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-974051', '2024-08-21'),
('GF-00180', 'AM5430B', 'Maharlika Fabrication', 'MF-Service', 'Handgun', 'REG-840481', '2024-04-13'),
('GF-00181', 'F388004', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-792313', '2024-07-23'),
('GF-00182', 'J665480', 'Amihan Works', 'AW-Compact', 'Handgun', 'REG-895947', '2024-10-20'),
('GF-00183', '35-34373', 'Silangan Precision', 'SP-Field', 'Rifle', 'REG-967490', '2024-08-01'),
('GF-00184', 'PC4804C', 'Pacific Crest', 'PC-Classic', 'Rifle', 'REG-302594', '2024-10-19'),
('GF-00185', '10-12811', 'Harbor Engineering', 'HE-Compact', 'Handgun', 'REG-770224', '2024-10-08');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00001', 'AP-00121', 'GF-00061', '2024-11-04', 'New', 'Approved', '2024-11-14', 'LC02', 'San Isidro Heights', 'ACQ-85745-24', '2024-07-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00001', 1, 'Identity', 'REF-493729', '2024-11-04', 'Accepted', '2024-11-10', NULL),
('APP-2024-00001', 2, 'Registration', 'REF-741115', '2024-11-08', 'Accepted', '2024-11-13', NULL),
('APP-2024-00001', 3, 'Acquisition', 'ACQ-85745-24', '2024-11-09', 'Accepted', '2024-11-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000001', 'APP-2024-00001', '2024-11-09', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00001', 'APP-2024-00001', '2024-11-19', '2024-11-19', '2025-11-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00002', 'AP-00177', 'GF-00122', '2024-11-04', 'New', 'UnderReview', NULL, 'LC05', 'Santa Elena', 'ACQ-49407-24', '2024-10-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00002', 1, 'Identity', 'DOC-680160', '2024-11-04', 'NeedsCorrection', '2024-11-06', 'The submitted name requires clarification against the application.'),
('APP-2024-00002', 2, 'Registration', 'DOC-999252', '2024-11-07', 'NeedsCorrection', '2024-11-10', 'The submitted name requires clarification against the application.'),
('APP-2024-00002', 3, 'Acquisition', 'ACQ-49407-24', '2024-11-09', 'Accepted', '2024-11-11', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00003', 'AP-00154', 'GF-00092', '2024-11-06', 'New', 'Approved', '2024-11-12', 'LC01', 'Luntian Central', 'ACQ-40579-24', '2024-07-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00003', 1, 'Identity', 'REF-742309', '2024-11-06', 'Accepted', '2024-11-07', NULL),
('APP-2024-00003', 2, 'Registration', 'REF-458360', '2024-11-09', 'Accepted', '2024-11-10', NULL),
('APP-2024-00003', 3, 'Acquisition', 'ACQ-40579-24', '2024-11-08', 'Accepted', '2024-11-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000002', 'APP-2024-00003', '2024-11-11', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00002', 'APP-2024-00003', '2024-11-16', '2024-11-16', '2025-11-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00004', 'AP-00159', 'GF-00131', '2024-11-06', 'New', 'Approved', '2024-11-25', 'LC04', 'Bagong Silangan', 'ACQ-91920-24', '2024-07-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00004', 1, 'Identity', 'DOC-580643', '2024-11-06', 'Accepted', '2024-11-08', NULL),
('APP-2024-00004', 2, 'Registration', 'FILE-179708', '2024-11-11', 'Accepted', '2024-11-17', NULL),
('APP-2024-00004', 3, 'Acquisition', 'ACQ-91920-24', '2024-11-09', 'Accepted', '2024-11-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000003', 'APP-2024-00004', '2024-11-11', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00003', 'APP-2024-00004', '2024-11-25', '2024-11-25', '2025-11-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00005', 'AP-00036', 'GF-00064', '2024-11-06', 'New', 'Approved', '2024-12-01', 'LC06', 'Maligaya', 'ACQ-51892-24', '2024-07-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00005', 1, 'Identity', 'REF-142577', '2024-11-06', 'Accepted', '2024-11-13', NULL),
('APP-2024-00005', 2, 'Registration', 'FILE-243634', '2024-11-08', 'Accepted', '2024-11-13', NULL),
('APP-2024-00005', 3, 'Acquisition', 'ACQ-51892-24', '2024-11-06', 'Accepted', '2024-11-07', NULL),
('APP-2024-00005', 4, 'Other', 'DOC-175247', '2024-11-10', 'Accepted', '2024-11-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000004', 'APP-2024-00005', '2024-11-09', 750, 'Online'),
('OR-2024-000005', 'APP-2024-00005', '2024-11-14', 150, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00004', 'APP-2024-00005', '2024-12-02', '2024-12-02', '2025-12-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00006', 'AP-00067', 'GF-00101', '2024-11-11', 'New', 'Approved', '2024-12-10', 'LC04', 'Bagong Silangan', 'ACQ-83790-24', '2024-10-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00006', 1, 'Identity', 'REF-669637', '2024-11-11', 'Accepted', '2024-11-18', NULL),
('APP-2024-00006', 2, 'Registration', 'REF-553012', '2024-11-16', 'Accepted', '2024-11-23', NULL),
('APP-2024-00006', 3, 'Acquisition', 'ACQ-83790-24', '2024-11-13', 'Accepted', '2024-11-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000006', 'APP-2024-00006', '2024-11-12', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00005', 'APP-2024-00006', '2024-12-15', '2024-12-15', '2025-12-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00007', 'AP-00001', 'GF-00101', '2024-11-11', 'New', 'Approved', '2024-11-17', 'LC01', 'Luntian Central', 'ACQ-52168-24', '2024-07-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00007', 1, 'Identity', 'FILE-983370', '2024-11-11', 'Accepted', '2024-11-17', NULL),
('APP-2024-00007', 2, 'Registration', 'REF-170074', '2024-11-14', 'Accepted', '2024-11-15', NULL),
('APP-2024-00007', 3, 'Acquisition', 'ACQ-52168-24', '2024-11-16', 'Accepted', '2024-11-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000007', 'APP-2024-00007', '2024-11-17', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00006', 'APP-2024-00007', '2024-11-21', '2024-11-21', '2025-11-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00008', 'AP-00004', 'GF-00003', '2024-11-14', 'New', 'Approved', '2024-12-07', 'LC01', 'Luntian Central', 'ACQ-40470-24', '2024-07-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00008', 1, 'Identity', 'FILE-440289', '2024-11-14', 'Accepted', '2024-11-19', NULL),
('APP-2024-00008', 2, 'Registration', 'FILE-207182', '2024-11-15', 'Accepted', '2024-11-20', NULL),
('APP-2024-00008', 3, 'Acquisition', 'ACQ-40470-24', '2024-11-17', 'Accepted', '2024-11-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000008', 'APP-2024-00008', '2024-11-25', 1200, 'Online'),
('OR-2024-000009', 'APP-2024-00008', '2024-11-21', 200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00007', 'APP-2024-00008', '2024-12-12', '2024-12-12', '2025-12-11', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00009', 'AP-00032', 'GF-00048', '2024-11-15', 'New', 'Approved', '2024-11-20', 'LC08', 'San Rafael Norte', 'ACQ-18925-24', '2024-08-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00009', 1, 'Identity', 'DOC-628006', '2024-11-15', 'Accepted', '2024-11-20', NULL),
('APP-2024-00009', 2, 'Registration', 'DOC-148155', '2024-11-17', 'Accepted', '2024-11-20', NULL),
('APP-2024-00009', 3, 'Acquisition', 'ACQ-18925-24', '2024-11-16', 'Accepted', '2024-11-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000010', 'APP-2024-00009', '2024-11-20', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00008', 'APP-2024-00009', '2024-11-25', '2024-11-25', '2025-11-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00010', 'AP-00114', 'GF-00156', '2024-11-16', 'New', 'Approved', '2024-11-23', 'LC01', 'Luntian Central', 'ACQ-78168-24', '2024-08-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00010', 1, 'Identity', 'REF-774750', '2024-11-16', 'Accepted', '2024-11-21', NULL),
('APP-2024-00010', 2, 'Registration', 'DOC-308296', '2024-11-19', 'Accepted', '2024-11-21', NULL),
('APP-2024-00010', 3, 'Acquisition', 'ACQ-78168-24', '2024-11-17', 'Accepted', '2024-11-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000011', 'APP-2024-00010', '2024-11-23', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00009', 'APP-2024-00010', '2024-11-28', '2024-11-28', '2025-11-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00011', 'AP-00003', 'GF-00101', '2024-11-16', 'New', 'Approved', '2024-11-29', 'LC05', 'Santa Elena', 'ACQ-77688-24', '2024-09-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00011', 1, 'Identity', 'REF-480370', '2024-11-16', 'Accepted', '2024-11-19', NULL),
('APP-2024-00011', 2, 'Registration', 'FILE-354196', '2024-11-18', 'Accepted', '2024-11-23', NULL),
('APP-2024-00011', 3, 'Acquisition', 'ACQ-77688-24', '2024-11-19', 'Accepted', '2024-11-26', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00010', 'APP-2024-00011', '2024-12-03', '2024-12-03', '2025-12-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00012', 'AP-00132', 'GF-00158', '2024-11-17', 'New', 'Rejected', '2024-12-09', 'LC03', 'Mabini East', 'ACQ-32429-24', '2024-08-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00012', 1, 'Identity', 'REF-781235', '2024-11-17', 'Accepted', '2024-11-24', NULL),
('APP-2024-00012', 2, 'Registration', 'FILE-746299', '2024-11-19', 'Accepted', '2024-11-22', NULL),
('APP-2024-00012', 3, 'Acquisition', 'ACQ-32429-24', '2024-11-18', 'NeedsCorrection', '2024-11-23', 'The submitted name requires clarification against the application.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000012', 'APP-2024-00012', '2024-11-28', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00013', 'AP-00014', 'GF-00122', '2024-11-18', 'New', 'Rejected', '2024-12-01', 'LC05', 'Santa Elena', 'ACQ-91433-24', '2024-09-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00013', 1, 'Identity', 'FILE-78737', '2024-11-18', 'Pending', NULL, NULL),
('APP-2024-00013', 2, 'Registration', 'REF-273527', '2024-11-18', 'NeedsCorrection', '2024-11-25', 'A clearer copy of the reference portion is requested.'),
('APP-2024-00013', 3, 'Acquisition', 'ACQ-91433-24', '2024-11-19', 'Accepted', '2024-11-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000013', 'APP-2024-00013', '2024-11-21', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00014', 'AP-00108', 'GF-00038', '2024-11-19', 'New', 'Approved', '2024-12-04', 'LC02', 'San Isidro Heights', 'ACQ-86907-24', '2024-10-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00014', 1, 'Identity', 'DOC-122519', '2024-11-19', 'Accepted', '2024-11-24', NULL),
('APP-2024-00014', 2, 'Registration', 'DOC-69904', '2024-11-19', 'Accepted', '2024-11-22', NULL),
('APP-2024-00014', 3, 'Acquisition', 'ACQ-86907-24', '2024-11-24', 'Accepted', '2024-11-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000014', 'APP-2024-00014', '2024-11-24', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00011', 'APP-2024-00014', '2024-12-05', '2024-12-05', '2025-12-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00015', 'AP-00012', 'GF-00041', '2024-11-19', 'New', 'Approved', '2024-12-12', 'LC01', 'Luntian Central', 'ACQ-15789-24', '2024-10-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00015', 1, 'Identity', 'DOC-572566', '2024-11-19', 'Accepted', '2024-11-22', NULL),
('APP-2024-00015', 2, 'Registration', 'FILE-649318', '2024-11-19', 'Accepted', '2024-11-26', NULL),
('APP-2024-00015', 3, 'Acquisition', 'ACQ-15789-24', '2024-11-22', 'Accepted', '2024-11-28', NULL),
('APP-2024-00015', 4, 'Other', 'REF-924742', '2024-11-21', 'Accepted', '2024-11-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000015', 'APP-2024-00015', '2024-11-20', 600, 'Online'),
('OR-2024-000016', 'APP-2024-00015', '2024-11-22', 100, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00016', 'AP-00096', 'GF-00007', '2024-11-21', 'New', 'Rejected', '2024-12-11', 'LC06', 'Maligaya', 'ACQ-16812-24', '2024-07-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00016', 1, 'Identity', 'REF-297773', '2024-11-21', 'NeedsCorrection', '2024-11-26', 'Please provide the missing page of the supporting document.'),
('APP-2024-00016', 2, 'Registration', 'FILE-72495', '2024-11-21', 'Accepted', '2024-11-26', NULL),
('APP-2024-00016', 3, 'Acquisition', 'ACQ-16812-24', '2024-11-21', 'Accepted', '2024-11-23', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00017', 'AP-00033', 'GF-00059', '2024-11-21', 'New', 'Approved', '2024-11-30', 'LC01', 'Luntian Central', 'ACQ-13981-24', '2024-10-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00017', 1, 'Identity', 'REF-109237', '2024-11-21', 'Accepted', '2024-11-24', NULL),
('APP-2024-00017', 2, 'Registration', 'DOC-872608', '2024-11-22', 'Accepted', '2024-11-29', NULL),
('APP-2024-00017', 3, 'Acquisition', 'ACQ-13981-24', '2024-11-26', 'Accepted', '2024-11-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000017', 'APP-2024-00017', '2024-11-21', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00012', 'APP-2024-00017', '2024-12-02', '2024-12-02', '2025-12-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00018', 'AP-00067', 'GF-00051', '2024-11-24', 'New', 'Approved', '2024-12-01', 'LC04', 'Bagong Silangan', 'ACQ-49537-24', '2024-11-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00018', 1, 'Identity', 'FILE-781979', '2024-11-24', 'Accepted', '2024-11-29', NULL),
('APP-2024-00018', 2, 'Registration', 'DOC-577775', '2024-11-25', 'Accepted', '2024-12-01', NULL),
('APP-2024-00018', 3, 'Acquisition', 'ACQ-49537-24', '2024-11-26', 'Accepted', '2024-11-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000018', 'APP-2024-00018', '2024-11-29', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00013', 'APP-2024-00018', '2024-12-05', '2024-12-05', '2025-12-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00019', 'AP-00003', 'GF-00117', '2024-11-26', 'New', 'Rejected', '2024-12-15', 'LC05', 'Santa Elena', 'ACQ-51372-24', '2024-09-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00019', 1, 'Identity', 'REF-63767', '2024-11-26', 'NeedsCorrection', '2024-11-28', 'The submitted name requires clarification against the application.'),
('APP-2024-00019', 2, 'Registration', 'FILE-923008', '2024-11-29', 'Accepted', '2024-12-02', NULL),
('APP-2024-00019', 3, 'Acquisition', 'ACQ-51372-24', '2024-11-30', 'Accepted', '2024-12-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000019', 'APP-2024-00019', '2024-11-29', 350, 'Online'),
('OR-2024-000020', 'APP-2024-00019', '2024-12-06', 150, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00020', 'AP-00040', 'GF-00054', '2024-11-28', 'New', 'Approved', '2024-12-27', 'LC05', 'Santa Elena', 'ACQ-87882-24', '2024-10-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00020', 1, 'Identity', 'REF-253784', '2024-11-28', 'Accepted', '2024-12-01', NULL),
('APP-2024-00020', 2, 'Registration', 'DOC-129400', '2024-11-29', 'Accepted', '2024-12-05', NULL),
('APP-2024-00020', 3, 'Acquisition', 'ACQ-87882-24', '2024-11-30', 'Accepted', '2024-12-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000021', 'APP-2024-00020', '2024-11-30', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00014', 'APP-2024-00020', '2024-12-30', '2024-12-30', '2025-12-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00021', 'AP-00077', 'GF-00036', '2024-11-29', 'New', 'Approved', '2024-12-14', 'LC05', 'Santa Elena', 'ACQ-88794-24', '2024-09-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00021', 1, 'Identity', 'DOC-721693', '2024-11-29', 'Accepted', '2024-12-04', NULL),
('APP-2024-00021', 2, 'Registration', 'REF-672028', '2024-12-04', 'Accepted', '2024-12-11', NULL),
('APP-2024-00021', 3, 'Acquisition', 'ACQ-88794-24', '2024-12-04', 'Accepted', '2024-12-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000022', 'APP-2024-00021', '2024-11-30', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00022', 'AP-00007', 'GF-00011', '2024-12-02', 'New', 'Approved', '2024-12-12', 'LC01', 'Luntian Central', 'ACQ-89613-24', '2024-09-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00022', 1, 'Identity', 'REF-810781', '2024-12-02', 'Accepted', '2024-12-04', NULL),
('APP-2024-00022', 2, 'Registration', 'REF-145039', '2024-12-03', 'Accepted', '2024-12-05', NULL),
('APP-2024-00022', 3, 'Acquisition', 'ACQ-89613-24', '2024-12-06', 'Accepted', '2024-12-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000023', 'APP-2024-00022', '2024-12-12', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00023', 'AP-00189', 'GF-00066', '2024-12-06', 'New', 'Approved', '2024-12-29', 'LC04', 'Bagong Silangan', 'ACQ-74406-24', '2024-10-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00023', 1, 'Identity', 'REF-172581', '2024-12-06', 'Accepted', '2024-12-13', NULL),
('APP-2024-00023', 2, 'Registration', 'FILE-340000', '2024-12-06', 'Accepted', '2024-12-12', NULL),
('APP-2024-00023', 3, 'Acquisition', 'ACQ-74406-24', '2024-12-10', 'Accepted', '2024-12-11', NULL),
('APP-2024-00023', 4, 'Other', 'FILE-901469', '2024-12-09', 'Accepted', '2024-12-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000024', 'APP-2024-00023', '2024-12-18', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00015', 'APP-2024-00023', '2025-01-02', '2025-01-02', '2026-01-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00024', 'AP-00190', 'GF-00016', '2024-12-06', 'New', 'Approved', '2024-12-27', 'LC02', 'San Isidro Heights', 'ACQ-76961-24', '2024-08-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00024', 1, 'Identity', 'FILE-67535', '2024-12-06', 'Accepted', '2024-12-10', NULL),
('APP-2024-00024', 2, 'Registration', 'DOC-32119', '2024-12-08', 'Accepted', '2024-12-09', NULL),
('APP-2024-00024', 3, 'Acquisition', 'ACQ-76961-24', '2024-12-06', 'Accepted', '2024-12-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000025', 'APP-2024-00024', '2024-12-16', 600, 'Cash'),
('OR-2024-000026', 'APP-2024-00024', '2024-12-14', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00016', 'APP-2024-00024', '2024-12-31', '2024-12-31', '2025-12-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00025', 'AP-00137', 'GF-00158', '2024-12-07', 'New', 'Approved', '2024-12-16', 'LC03', 'Mabini East', 'ACQ-15395-24', '2024-09-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00025', 1, 'Identity', 'DOC-246202', '2024-12-07', 'Accepted', '2024-12-14', NULL),
('APP-2024-00025', 2, 'Registration', 'DOC-672842', '2024-12-11', 'Accepted', '2024-12-13', NULL),
('APP-2024-00025', 3, 'Acquisition', 'ACQ-15395-24', '2024-12-07', 'Accepted', '2024-12-13', NULL),
('APP-2024-00025', 4, 'Other', 'REF-580212', '2024-12-12', 'Accepted', '2024-12-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000027', 'APP-2024-00025', '2024-12-13', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00017', 'APP-2024-00025', '2024-12-17', '2024-12-17', '2025-12-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00026', 'AP-00151', 'GF-00022', '2024-12-08', 'New', 'Approved', '2024-12-27', 'LC06', 'Maligaya', 'ACQ-49542-24', '2024-09-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00026', 1, 'Identity', 'FILE-646196', '2024-12-08', 'Accepted', '2024-12-10', NULL),
('APP-2024-00026', 2, 'Registration', 'DOC-153320', '2024-12-10', 'Accepted', '2024-12-16', NULL),
('APP-2024-00026', 3, 'Acquisition', 'ACQ-49542-24', '2024-12-12', 'Accepted', '2024-12-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000028', 'APP-2024-00026', '2024-12-15', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00018', 'APP-2024-00026', '2024-12-30', '2024-12-30', '2025-12-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00027', 'AP-00180', 'GF-00062', '2024-12-11', 'New', 'Approved', '2024-12-29', 'LC07', 'Pulo Verde', 'ACQ-15715-24', '2024-11-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00027', 1, 'Identity', 'DOC-879941', '2024-12-11', 'Accepted', '2024-12-14', NULL),
('APP-2024-00027', 2, 'Registration', 'REF-541709', '2024-12-11', 'Accepted', '2024-12-12', NULL),
('APP-2024-00027', 3, 'Acquisition', 'ACQ-15715-24', '2024-12-15', 'Accepted', '2024-12-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000029', 'APP-2024-00027', '2024-12-16', 900, 'Online'),
('OR-2024-000030', 'APP-2024-00027', '2024-12-16', 150, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00019', 'APP-2024-00027', '2025-01-03', '2025-01-03', '2026-01-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00028', 'AP-00043', 'GF-00037', '2024-12-11', 'New', 'Approved', '2024-12-29', 'LC02', 'San Isidro Heights', 'ACQ-15987-24', '2024-11-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00028', 1, 'Identity', 'DOC-522455', '2024-12-11', 'Accepted', '2024-12-14', NULL),
('APP-2024-00028', 2, 'Registration', 'FILE-403468', '2024-12-12', 'Accepted', '2024-12-15', NULL),
('APP-2024-00028', 3, 'Acquisition', 'ACQ-15987-24', '2024-12-13', 'Accepted', '2024-12-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000031', 'APP-2024-00028', '2024-12-15', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2024-00020', 'APP-2024-00028', '2024-12-30', '2024-12-30', '2025-12-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00029', 'AP-00134', 'GF-00144', '2024-12-12', 'New', 'Submitted', NULL, 'LC07', 'Pulo Verde', 'ACQ-90160-24', '2024-09-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00029', 1, 'Identity', 'FILE-396587', '2024-12-12', 'Pending', NULL, NULL),
('APP-2024-00029', 2, 'Registration', 'DOC-662105', '2024-12-16', 'Pending', NULL, NULL),
('APP-2024-00029', 3, 'Acquisition', 'ACQ-90160-24', '2024-12-13', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00030', 'AP-00122', 'GF-00032', '2024-12-17', 'New', 'Submitted', NULL, 'LC03', 'Mabini East', 'ACQ-76473-24', '2024-12-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00030', 1, 'Identity', 'FILE-746438', '2024-12-17', 'Pending', NULL, NULL),
('APP-2024-00030', 2, 'Registration', 'REF-629104', '2024-12-21', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000032', 'APP-2024-00030', '2024-12-17', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00031', 'AP-00167', 'GF-00056', '2024-12-17', 'New', 'Approved', '2025-01-22', 'LC01', 'Luntian Central', 'ACQ-33538-24', '2024-09-05', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00031', 1, 'Identity', 'DOC-123998', '2024-12-17', 'Accepted', '2024-12-19', NULL),
('APP-2024-00031', 2, 'Registration', 'FILE-872273', '2024-12-20', 'Accepted', '2024-12-24', NULL),
('APP-2024-00031', 3, 'Acquisition', 'ACQ-33538-24', '2024-12-20', 'Accepted', '2024-12-23', NULL),
('APP-2024-00031', 4, 'Other', 'DOC-356092', '2024-12-17', 'Accepted', '2024-12-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000033', 'APP-2024-00031', '2024-12-24', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00021', 'APP-2024-00031', '2025-01-27', '2025-01-27', '2026-01-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00032', 'AP-00163', 'GF-00159', '2024-12-19', 'New', 'Approved', '2025-01-10', 'LC01', 'Luntian Central', 'ACQ-46331-24', '2024-12-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00032', 1, 'Identity', 'REF-738780', '2024-12-19', 'Accepted', '2024-12-21', NULL),
('APP-2024-00032', 2, 'Registration', 'FILE-586025', '2024-12-20', 'Accepted', '2024-12-23', NULL),
('APP-2024-00032', 3, 'Acquisition', 'ACQ-46331-24', '2024-12-21', 'Accepted', '2024-12-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000034', 'APP-2024-00032', '2024-12-30', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00022', 'APP-2024-00032', '2025-01-11', '2025-01-11', '2026-01-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00033', 'AP-00105', 'GF-00147', '2024-12-21', 'New', 'Approved', '2025-01-02', 'LC04', 'Bagong Silangan', 'ACQ-72516-24', '2024-11-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00033', 1, 'Identity', 'DOC-832740', '2024-12-21', 'Accepted', '2024-12-27', NULL),
('APP-2024-00033', 2, 'Registration', 'REF-230209', '2024-12-22', 'Accepted', '2024-12-23', NULL),
('APP-2024-00033', 3, 'Acquisition', 'ACQ-72516-24', '2024-12-26', 'Accepted', '2024-12-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000035', 'APP-2024-00033', '2024-12-27', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00023', 'APP-2024-00033', '2025-01-07', '2025-01-07', '2026-01-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00034', 'AP-00131', 'GF-00064', '2024-12-22', 'New', 'Approved', '2025-02-14', 'LC05', 'Santa Elena', 'ACQ-21445-24', '2024-09-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00034', 1, 'Identity', 'DOC-442706', '2024-12-22', 'Accepted', '2024-12-24', NULL),
('APP-2024-00034', 2, 'Registration', 'FILE-387972', '2024-12-27', 'Accepted', '2024-12-31', NULL),
('APP-2024-00034', 3, 'Acquisition', 'ACQ-21445-24', '2024-12-27', 'Accepted', '2025-01-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000036', 'APP-2024-00034', '2024-12-31', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00024', 'APP-2024-00034', '2025-02-14', '2025-02-14', '2026-02-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00035', 'AP-00049', 'GF-00027', '2024-12-24', 'New', 'Rejected', '2025-01-07', 'LC04', 'Bagong Silangan', 'ACQ-40003-24', '2024-09-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00035', 1, 'Identity', 'DOC-146072', '2024-12-24', 'Pending', NULL, NULL),
('APP-2024-00035', 2, 'Registration', 'DOC-926168', '2024-12-28', 'NeedsCorrection', '2024-12-31', 'The submitted name requires clarification against the application.'),
('APP-2024-00035', 3, 'Acquisition', 'ACQ-40003-24', '2024-12-26', 'NeedsCorrection', '2024-12-27', 'The date on the document needs clarification.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2024-000037', 'APP-2024-00035', '2024-12-29', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00036', 'AP-00118', 'GF-00074', '2024-12-27', 'New', 'Approved', '2025-01-04', 'LC01', 'Luntian Central', 'ACQ-63820-24', '2024-11-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00036', 1, 'Identity', 'REF-817571', '2024-12-27', 'Accepted', '2024-12-30', NULL),
('APP-2024-00036', 2, 'Registration', 'DOC-625544', '2024-12-30', 'Accepted', '2025-01-02', NULL),
('APP-2024-00036', 3, 'Acquisition', 'ACQ-63820-24', '2025-01-01', 'Accepted', '2025-01-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000038', 'APP-2024-00036', '2025-01-02', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00025', 'APP-2024-00036', '2025-01-07', '2025-01-07', '2026-01-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00037', 'AP-00064', 'GF-00001', '2024-12-27', 'New', 'Approved', '2025-01-11', 'LC07', 'Pulo Verde', 'ACQ-65581-24', '2024-10-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00037', 1, 'Identity', 'DOC-808790', '2024-12-27', 'Accepted', '2024-12-29', NULL),
('APP-2024-00037', 2, 'Registration', 'FILE-591042', '2024-12-29', 'Accepted', '2025-01-03', NULL),
('APP-2024-00037', 3, 'Acquisition', 'ACQ-65581-24', '2024-12-27', 'Accepted', '2024-12-29', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00026', 'APP-2024-00037', '2025-01-12', '2025-01-12', '2026-01-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00038', 'AP-00189', 'GF-00072', '2024-12-31', 'New', 'Approved', '2025-01-03', 'LC04', 'Bagong Silangan', 'ACQ-71714-24', '2024-09-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00038', 1, 'Identity', 'FILE-960747', '2024-12-31', 'Accepted', '2025-01-01', NULL),
('APP-2024-00038', 2, 'Registration', 'DOC-284202', '2024-12-31', 'Accepted', '2025-01-03', NULL),
('APP-2024-00038', 3, 'Acquisition', 'ACQ-71714-24', '2024-12-31', 'Accepted', '2025-01-03', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2024-00039', 'AP-00176', 'GF-00146', '2024-12-31', 'New', 'Approved', '2025-01-10', 'LC04', 'Bagong Silangan', 'ACQ-13408-24', '2024-10-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2024-00039', 1, 'Identity', 'REF-720400', '2024-12-31', 'Accepted', '2025-01-03', NULL),
('APP-2024-00039', 2, 'Registration', 'REF-269620', '2025-01-04', 'Accepted', '2025-01-10', NULL),
('APP-2024-00039', 3, 'Acquisition', 'ACQ-13408-24', '2025-01-04', 'Accepted', '2025-01-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000039', 'APP-2024-00039', '2025-01-04', 750, 'BankTransfer'),
('OR-2025-000040', 'APP-2024-00039', '2025-01-10', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00027', 'APP-2024-00039', '2025-01-15', '2025-01-15', '2026-01-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00040', 'AP-00181', 'GF-00126', '2025-01-02', 'New', 'Approved', '2025-01-13', 'LC07', 'Pulo Verde', 'ACQ-56479-25', '2024-10-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00040', 1, 'Identity', 'REF-936077', '2025-01-02', 'Accepted', '2025-01-04', NULL),
('APP-2025-00040', 2, 'Registration', 'DOC-830241', '2025-01-07', 'Accepted', '2025-01-08', NULL),
('APP-2025-00040', 3, 'Acquisition', 'ACQ-56479-25', '2025-01-04', 'Accepted', '2025-01-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000041', 'APP-2025-00040', '2025-01-04', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00028', 'APP-2025-00040', '2025-01-16', '2025-01-16', '2026-01-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00041', 'AP-00048', 'GF-00052', '2025-01-04', 'New', 'Rejected', '2025-01-13', 'LC08', 'San Rafael Norte', 'ACQ-54733-25', '2024-09-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00041', 1, 'Identity', 'FILE-867638', '2025-01-04', 'Accepted', '2025-01-10', NULL),
('APP-2025-00041', 2, 'Registration', 'FILE-236591', '2025-01-06', 'Pending', NULL, NULL),
('APP-2025-00041', 3, 'Acquisition', 'ACQ-54733-25', '2025-01-04', 'Accepted', '2025-01-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000042', 'APP-2025-00041', '2025-01-13', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00042', 'AP-00105', 'GF-00106', '2025-01-06', 'New', 'Approved', '2025-01-26', 'LC04', 'Bagong Silangan', 'ACQ-45563-25', '2024-10-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00042', 1, 'Identity', 'DOC-423568', '2025-01-06', 'Accepted', '2025-01-07', NULL),
('APP-2025-00042', 2, 'Registration', 'DOC-150285', '2025-01-09', 'Accepted', '2025-01-16', NULL),
('APP-2025-00042', 3, 'Acquisition', 'ACQ-45563-25', '2025-01-11', 'Accepted', '2025-01-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000043', 'APP-2025-00042', '2025-01-06', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00029', 'APP-2025-00042', '2025-01-29', '2025-01-29', '2026-01-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00043', 'AP-00006', 'GF-00042', '2025-01-06', 'New', 'Approved', '2025-01-30', 'LC03', 'Mabini East', 'ACQ-48440-25', '2024-10-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00043', 1, 'Identity', 'DOC-875282', '2025-01-06', 'Accepted', '2025-01-08', NULL),
('APP-2025-00043', 2, 'Registration', 'FILE-777975', '2025-01-08', 'Accepted', '2025-01-14', NULL),
('APP-2025-00043', 3, 'Acquisition', 'ACQ-48440-25', '2025-01-09', 'Accepted', '2025-01-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000044', 'APP-2025-00043', '2025-01-14', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00030', 'APP-2025-00043', '2025-02-02', '2025-02-02', '2026-02-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00044', 'AP-00173', 'GF-00103', '2025-01-06', 'New', 'Approved', '2025-01-11', 'LC01', 'Luntian Central', 'ACQ-94756-25', '2024-11-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00044', 1, 'Identity', 'DOC-575610', '2025-01-06', 'Accepted', '2025-01-10', NULL),
('APP-2025-00044', 2, 'Registration', 'FILE-135413', '2025-01-06', 'Accepted', '2025-01-11', NULL),
('APP-2025-00044', 3, 'Acquisition', 'ACQ-94756-25', '2025-01-11', 'Accepted', '2025-01-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000045', 'APP-2025-00044', '2025-01-06', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00031', 'APP-2025-00044', '2025-01-16', '2025-01-16', '2026-01-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00045', 'AP-00015', 'GF-00018', '2025-01-07', 'New', 'Approved', '2025-01-18', 'LC03', 'Mabini East', 'ACQ-74034-25', '2024-09-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00045', 1, 'Identity', 'REF-218424', '2025-01-07', 'Accepted', '2025-01-09', NULL),
('APP-2025-00045', 2, 'Registration', 'FILE-804174', '2025-01-08', 'Accepted', '2025-01-09', NULL),
('APP-2025-00045', 3, 'Acquisition', 'ACQ-74034-25', '2025-01-09', 'Accepted', '2025-01-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000046', 'APP-2025-00045', '2025-01-13', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00032', 'APP-2025-00045', '2025-01-18', '2025-01-18', '2026-01-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00046', 'AP-00155', 'GF-00156', '2025-01-08', 'New', 'Withdrawn', NULL, 'LC01', 'Luntian Central', 'ACQ-56684-25', '2024-10-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00046', 1, 'Identity', 'DOC-407192', '2025-01-08', 'NeedsCorrection', '2025-01-12', 'The date on the document needs clarification.'),
('APP-2025-00046', 2, 'Registration', 'DOC-616603', '2025-01-10', 'Accepted', '2025-01-13', NULL),
('APP-2025-00046', 3, 'Acquisition', 'ACQ-56684-25', '2025-01-08', 'Accepted', '2025-01-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000047', 'APP-2025-00046', '2025-01-20', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00047', 'AP-00088', 'GF-00129', '2025-01-08', 'New', 'Approved', '2025-01-29', 'LC06', 'Maligaya', 'ACQ-26256-25', '2024-11-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00047', 1, 'Identity', 'DOC-811701', '2025-01-08', 'Accepted', '2025-01-15', NULL),
('APP-2025-00047', 2, 'Registration', 'DOC-77348', '2025-01-09', 'Accepted', '2025-01-10', NULL),
('APP-2025-00047', 3, 'Acquisition', 'ACQ-26256-25', '2025-01-13', 'Accepted', '2025-01-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000048', 'APP-2025-00047', '2025-01-09', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00033', 'APP-2025-00047', '2025-01-29', '2025-01-29', '2026-01-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00048', 'AP-00144', 'GF-00008', '2025-01-10', 'New', 'Approved', '2025-02-01', 'LC02', 'San Isidro Heights', 'ACQ-15478-25', '2024-10-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00048', 1, 'Identity', 'DOC-66635', '2025-01-10', 'Accepted', '2025-01-14', NULL),
('APP-2025-00048', 2, 'Registration', 'REF-147483', '2025-01-12', 'Accepted', '2025-01-16', NULL),
('APP-2025-00048', 3, 'Acquisition', 'ACQ-15478-25', '2025-01-12', 'Accepted', '2025-01-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000049', 'APP-2025-00048', '2025-01-18', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00034', 'APP-2025-00048', '2025-02-01', '2025-02-01', '2026-01-31', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00049', 'AP-00095', 'GF-00148', '2025-01-13', 'New', 'Withdrawn', NULL, 'LC07', 'Pulo Verde', 'ACQ-88333-25', '2024-12-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00049', 1, 'Identity', 'DOC-70944', '2025-01-13', 'Accepted', '2025-01-14', NULL),
('APP-2025-00049', 2, 'Registration', 'REF-877504', '2025-01-14', 'Pending', NULL, NULL),
('APP-2025-00049', 3, 'Acquisition', 'ACQ-88333-25', '2025-01-16', 'NeedsCorrection', '2025-01-19', 'The submitted name requires clarification against the application.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000050', 'APP-2025-00049', '2025-01-23', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00050', 'AP-00016', 'GF-00121', '2025-01-14', 'New', 'Withdrawn', NULL, 'LC06', 'Maligaya', 'ACQ-46863-25', '2024-11-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00050', 1, 'Identity', 'FILE-870203', '2025-01-14', 'Accepted', '2025-01-21', NULL),
('APP-2025-00050', 2, 'Registration', 'FILE-945608', '2025-01-14', 'Accepted', '2025-01-15', NULL),
('APP-2025-00050', 3, 'Acquisition', 'ACQ-46863-25', '2025-01-18', 'Accepted', '2025-01-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000051', 'APP-2025-00050', '2025-01-22', 450, 'Cash'),
('OR-2025-000052', 'APP-2025-00050', '2025-01-19', 200, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00051', 'AP-00006', 'GF-00149', '2025-01-14', 'New', 'Rejected', '2025-01-17', 'LC03', 'Mabini East', 'ACQ-23442-25', '2024-10-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00051', 1, 'Identity', 'FILE-308197', '2025-01-14', 'Accepted', '2025-01-17', NULL),
('APP-2025-00051', 2, 'Registration', 'REF-709392', '2025-01-14', 'Accepted', '2025-01-17', NULL),
('APP-2025-00051', 3, 'Acquisition', 'ACQ-23442-25', '2025-01-16', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000053', 'APP-2025-00051', '2025-01-16', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00052', 'AP-00067', 'GF-00065', '2025-01-15', 'New', 'Approved', '2025-01-22', 'LC04', 'Bagong Silangan', 'ACQ-30880-25', '2024-09-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00052', 1, 'Identity', 'DOC-639206', '2025-01-15', 'Accepted', '2025-01-21', NULL),
('APP-2025-00052', 2, 'Registration', 'REF-434851', '2025-01-17', 'Accepted', '2025-01-18', NULL),
('APP-2025-00052', 3, 'Acquisition', 'ACQ-30880-25', '2025-01-18', 'Accepted', '2025-01-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000054', 'APP-2025-00052', '2025-01-17', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00035', 'APP-2025-00052', '2025-01-23', '2025-01-23', '2026-01-22', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00053', 'AP-00044', 'GF-00106', '2025-01-16', 'New', 'Approved', '2025-01-27', 'LC01', 'Luntian Central', 'ACQ-67931-25', '2024-12-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00053', 1, 'Identity', 'REF-262359', '2025-01-16', 'Accepted', '2025-01-18', NULL),
('APP-2025-00053', 2, 'Registration', 'FILE-829701', '2025-01-21', 'Accepted', '2025-01-24', NULL),
('APP-2025-00053', 3, 'Acquisition', 'ACQ-67931-25', '2025-01-20', 'Accepted', '2025-01-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000055', 'APP-2025-00053', '2025-01-26', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00036', 'APP-2025-00053', '2025-01-27', '2025-01-27', '2026-01-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00054', 'AP-00002', 'GF-00039', '2025-01-17', 'New', 'Rejected', '2025-02-25', 'LC07', 'Pulo Verde', 'ACQ-97528-25', '2025-01-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00054', 1, 'Identity', 'DOC-33657', '2025-01-17', 'Accepted', '2025-01-21', NULL),
('APP-2025-00054', 2, 'Registration', 'FILE-674847', '2025-01-19', 'Pending', NULL, NULL),
('APP-2025-00054', 3, 'Acquisition', 'ACQ-97528-25', '2025-01-18', 'NeedsCorrection', '2025-01-21', 'A clearer copy of the reference portion is requested.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000056', 'APP-2025-00054', '2025-01-20', 1200, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00055', 'AP-00181', 'GF-00141', '2025-01-17', 'New', 'Approved', '2025-03-16', 'LC07', 'Pulo Verde', 'ACQ-61632-25', '2024-12-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00055', 1, 'Identity', 'FILE-112780', '2025-01-17', 'Accepted', '2025-01-19', NULL),
('APP-2025-00055', 2, 'Registration', 'FILE-100641', '2025-01-22', 'Accepted', '2025-01-26', NULL),
('APP-2025-00055', 3, 'Acquisition', 'ACQ-61632-25', '2025-01-17', 'Accepted', '2025-01-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000057', 'APP-2025-00055', '2025-01-24', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00037', 'APP-2025-00055', '2025-03-19', '2025-03-19', '2026-03-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00056', 'AP-00121', 'GF-00106', '2025-01-18', 'New', 'Approved', '2025-02-01', 'LC02', 'San Isidro Heights', 'ACQ-39194-25', '2024-12-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00056', 1, 'Identity', 'DOC-530572', '2025-01-18', 'Accepted', '2025-01-23', NULL),
('APP-2025-00056', 2, 'Registration', 'REF-438462', '2025-01-23', 'Accepted', '2025-01-27', NULL),
('APP-2025-00056', 3, 'Acquisition', 'ACQ-39194-25', '2025-01-18', 'Accepted', '2025-01-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000058', 'APP-2025-00056', '2025-01-24', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00038', 'APP-2025-00056', '2025-02-06', '2025-02-06', '2026-02-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00057', 'AP-00124', 'GF-00007', '2025-01-18', 'New', 'Approved', '2025-01-22', 'LC06', 'Maligaya', 'ACQ-97339-25', '2024-09-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00057', 1, 'Identity', 'FILE-982091', '2025-01-18', 'Accepted', '2025-01-21', NULL),
('APP-2025-00057', 2, 'Registration', 'DOC-779100', '2025-01-19', 'Accepted', '2025-01-22', NULL),
('APP-2025-00057', 3, 'Acquisition', 'ACQ-97339-25', '2025-01-22', 'Accepted', '2025-01-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000059', 'APP-2025-00057', '2025-01-22', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00039', 'APP-2025-00057', '2025-01-25', '2025-01-25', '2026-01-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00058', 'AP-00100', 'GF-00006', '2025-01-20', 'New', 'Submitted', NULL, 'LC04', 'Bagong Silangan', 'ACQ-55162-25', '2024-11-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00058', 1, 'Identity', 'DOC-780646', '2025-01-20', 'Pending', NULL, NULL),
('APP-2025-00058', 2, 'Registration', 'REF-547713', '2025-01-23', 'Pending', NULL, NULL),
('APP-2025-00058', 3, 'Acquisition', 'ACQ-55162-25', '2025-01-23', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00059', 'AP-00091', 'GF-00010', '2025-01-20', 'New', 'Rejected', '2025-01-30', 'LC02', 'San Isidro Heights', 'ACQ-29730-25', '2024-09-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00059', 1, 'Identity', 'FILE-976740', '2025-01-20', 'Pending', NULL, NULL),
('APP-2025-00059', 2, 'Registration', 'REF-549820', '2025-01-25', 'Accepted', '2025-01-30', NULL),
('APP-2025-00059', 3, 'Acquisition', 'ACQ-29730-25', '2025-01-23', 'Accepted', '2025-01-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000060', 'APP-2025-00059', '2025-01-20', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00060', 'AP-00180', 'GF-00076', '2025-01-26', 'New', 'Withdrawn', NULL, 'LC07', 'Pulo Verde', 'ACQ-71916-25', '2024-10-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00060', 1, 'Identity', 'DOC-155505', '2025-01-26', 'Pending', NULL, NULL),
('APP-2025-00060', 2, 'Registration', 'DOC-593831', '2025-01-28', 'Accepted', '2025-01-30', NULL),
('APP-2025-00060', 3, 'Acquisition', 'ACQ-71916-25', '2025-01-28', 'NeedsCorrection', '2025-01-31', 'A clearer copy of the reference portion is requested.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00061', 'AP-00124', 'GF-00065', '2025-01-27', 'New', 'Approved', '2025-02-14', 'LC06', 'Maligaya', 'ACQ-81169-25', '2024-12-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00061', 1, 'Identity', 'DOC-180345', '2025-01-27', 'Accepted', '2025-01-29', NULL),
('APP-2025-00061', 2, 'Registration', 'FILE-725497', '2025-01-27', 'Accepted', '2025-02-03', NULL),
('APP-2025-00061', 3, 'Acquisition', 'ACQ-81169-25', '2025-02-01', 'Accepted', '2025-02-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000061', 'APP-2025-00061', '2025-01-30', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00040', 'APP-2025-00061', '2025-02-16', '2025-02-16', '2026-02-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00062', 'AP-00185', 'GF-00005', '2025-01-27', 'New', 'Approved', '2025-02-19', 'LC03', 'Mabini East', 'ACQ-49726-25', '2024-10-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00062', 1, 'Identity', 'REF-624942', '2025-01-27', 'Accepted', '2025-02-02', NULL),
('APP-2025-00062', 2, 'Registration', 'FILE-388422', '2025-01-29', 'Accepted', '2025-02-02', NULL),
('APP-2025-00062', 3, 'Acquisition', 'ACQ-49726-25', '2025-01-31', 'Accepted', '2025-02-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000062', 'APP-2025-00062', '2025-02-06', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00041', 'APP-2025-00062', '2025-02-19', '2025-02-19', '2026-02-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00063', 'AP-00072', 'GF-00003', '2025-01-27', 'New', 'Submitted', NULL, 'LC08', 'San Rafael Norte', 'ACQ-30647-25', '2024-11-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00063', 1, 'Identity', 'DOC-282469', '2025-01-27', 'Pending', NULL, NULL),
('APP-2025-00063', 2, 'Registration', 'DOC-291037', '2025-02-01', 'Pending', NULL, NULL),
('APP-2025-00063', 3, 'Acquisition', 'ACQ-30647-25', '2025-01-30', 'Pending', NULL, NULL),
('APP-2025-00063', 4, 'Other', 'FILE-639493', '2025-01-29', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000063', 'APP-2025-00063', '2025-01-31', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00064', 'AP-00108', 'GF-00022', '2025-01-29', 'New', 'Approved', '2025-02-01', 'LC02', 'San Isidro Heights', 'ACQ-57761-25', '2024-12-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00064', 1, 'Identity', 'FILE-547377', '2025-01-29', 'Accepted', '2025-01-31', NULL),
('APP-2025-00064', 2, 'Registration', 'FILE-293800', '2025-01-31', 'Accepted', '2025-02-01', NULL),
('APP-2025-00064', 3, 'Acquisition', 'ACQ-57761-25', '2025-01-29', 'Accepted', '2025-02-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000064', 'APP-2025-00064', '2025-01-31', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00042', 'APP-2025-00064', '2025-02-03', '2025-02-03', '2026-02-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00065', 'AP-00062', 'GF-00128', '2025-01-29', 'New', 'Approved', '2025-02-02', 'LC01', 'Luntian Central', 'ACQ-74388-25', '2024-12-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00065', 1, 'Identity', 'REF-938971', '2025-01-29', 'Accepted', '2025-02-01', NULL),
('APP-2025-00065', 2, 'Registration', 'REF-555801', '2025-01-31', 'Accepted', '2025-02-02', NULL),
('APP-2025-00065', 3, 'Acquisition', 'ACQ-74388-25', '2025-02-01', 'Accepted', '2025-02-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000065', 'APP-2025-00065', '2025-02-02', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00043', 'APP-2025-00065', '2025-02-07', '2025-02-07', '2026-02-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00066', 'AP-00051', 'GF-00131', '2025-01-30', 'New', 'Approved', '2025-02-02', 'LC02', 'San Isidro Heights', 'ACQ-71017-25', '2024-10-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00066', 1, 'Identity', 'REF-856825', '2025-01-30', 'Accepted', '2025-02-02', NULL),
('APP-2025-00066', 2, 'Registration', 'DOC-125060', '2025-01-31', 'Accepted', '2025-02-02', NULL),
('APP-2025-00066', 3, 'Acquisition', 'ACQ-71017-25', '2025-02-01', 'Accepted', '2025-02-02', NULL),
('APP-2025-00066', 4, 'Other', 'DOC-61906', '2025-01-30', 'Accepted', '2025-02-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000066', 'APP-2025-00066', '2025-02-02', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00044', 'APP-2025-00066', '2025-02-03', '2025-02-03', '2026-02-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00067', 'AP-00057', 'GF-00022', '2025-02-01', 'New', 'Approved', '2025-02-22', 'LC03', 'Mabini East', 'ACQ-22160-25', '2024-11-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00067', 1, 'Identity', 'REF-805079', '2025-02-01', 'Accepted', '2025-02-03', NULL),
('APP-2025-00067', 2, 'Registration', 'DOC-513425', '2025-02-02', 'Accepted', '2025-02-08', NULL),
('APP-2025-00067', 3, 'Acquisition', 'ACQ-22160-25', '2025-02-05', 'Accepted', '2025-02-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000067', 'APP-2025-00067', '2025-02-04', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00045', 'APP-2025-00067', '2025-02-22', '2025-02-22', '2026-02-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00068', 'AP-00030', 'GF-00156', '2025-02-01', 'New', 'Approved', '2025-02-20', 'LC06', 'Maligaya', 'ACQ-28164-25', '2024-10-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00068', 1, 'Identity', 'FILE-607040', '2025-02-01', 'Accepted', '2025-02-06', NULL),
('APP-2025-00068', 2, 'Registration', 'FILE-650799', '2025-02-05', 'Accepted', '2025-02-10', NULL),
('APP-2025-00068', 3, 'Acquisition', 'ACQ-28164-25', '2025-02-04', 'Accepted', '2025-02-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000068', 'APP-2025-00068', '2025-02-11', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00069', 'AP-00031', 'GF-00131', '2025-02-01', 'New', 'Approved', '2025-02-26', 'LC04', 'Bagong Silangan', 'ACQ-47410-25', '2025-01-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00069', 1, 'Identity', 'DOC-848397', '2025-02-01', 'Accepted', '2025-02-05', NULL),
('APP-2025-00069', 2, 'Registration', 'FILE-659055', '2025-02-04', 'Accepted', '2025-02-07', NULL),
('APP-2025-00069', 3, 'Acquisition', 'ACQ-47410-25', '2025-02-02', 'Accepted', '2025-02-04', NULL),
('APP-2025-00069', 4, 'Other', 'REF-596938', '2025-02-05', 'Accepted', '2025-02-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000069', 'APP-2025-00069', '2025-02-09', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00046', 'APP-2025-00069', '2025-02-28', '2025-02-28', '2026-02-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00070', 'AP-00083', 'GF-00070', '2025-02-01', 'New', 'Approved', '2025-02-14', 'LC08', 'San Rafael Norte', 'ACQ-46898-25', '2024-10-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00070', 1, 'Identity', 'FILE-335825', '2025-02-01', 'Accepted', '2025-02-04', NULL),
('APP-2025-00070', 2, 'Registration', 'REF-667783', '2025-02-06', 'Accepted', '2025-02-10', NULL),
('APP-2025-00070', 3, 'Acquisition', 'ACQ-46898-25', '2025-02-03', 'Accepted', '2025-02-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000070', 'APP-2025-00070', '2025-02-08', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00047', 'APP-2025-00070', '2025-02-18', '2025-02-18', '2026-02-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00071', 'AP-00074', 'GF-00141', '2025-02-02', 'New', 'Approved', '2025-02-26', 'LC02', 'San Isidro Heights', 'ACQ-90821-25', '2025-01-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00071', 1, 'Identity', 'FILE-614962', '2025-02-02', 'Accepted', '2025-02-08', NULL),
('APP-2025-00071', 2, 'Registration', 'DOC-257484', '2025-02-04', 'Accepted', '2025-02-05', NULL),
('APP-2025-00071', 3, 'Acquisition', 'ACQ-90821-25', '2025-02-06', 'Accepted', '2025-02-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000071', 'APP-2025-00071', '2025-02-12', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00048', 'APP-2025-00071', '2025-03-02', '2025-03-02', '2026-03-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00072', 'AP-00048', 'GF-00155', '2025-02-02', 'New', 'Submitted', NULL, 'LC03', 'Mabini East', 'ACQ-23941-25', '2024-10-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00072', 1, 'Identity', 'DOC-395406', '2025-02-02', 'Pending', NULL, NULL),
('APP-2025-00072', 2, 'Registration', 'DOC-675466', '2025-02-07', 'Pending', NULL, NULL),
('APP-2025-00072', 3, 'Acquisition', 'ACQ-23941-25', '2025-02-05', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000072', 'APP-2025-00072', '2025-02-09', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00073', 'AP-00152', 'GF-00001', '2025-02-03', 'New', 'UnderReview', NULL, 'LC08', 'San Rafael Norte', 'ACQ-86014-25', '2025-01-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00073', 1, 'Identity', 'FILE-568753', '2025-02-03', 'Pending', NULL, NULL),
('APP-2025-00073', 2, 'Registration', 'DOC-572672', '2025-02-08', 'Accepted', '2025-02-13', NULL),
('APP-2025-00073', 3, 'Acquisition', 'ACQ-86014-25', '2025-02-06', 'Accepted', '2025-02-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000073', 'APP-2025-00073', '2025-02-07', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00074', 'AP-00044', 'GF-00031', '2025-02-03', 'New', 'Approved', '2025-02-27', 'LC08', 'San Rafael Norte', 'ACQ-10334-25', '2024-12-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00074', 1, 'Identity', 'FILE-602989', '2025-02-03', 'Accepted', '2025-02-04', NULL),
('APP-2025-00074', 2, 'Registration', 'REF-331271', '2025-02-07', 'Accepted', '2025-02-14', NULL),
('APP-2025-00074', 3, 'Acquisition', 'ACQ-10334-25', '2025-02-08', 'Accepted', '2025-02-12', NULL),
('APP-2025-00074', 4, 'Other', 'FILE-291564', '2025-02-04', 'Accepted', '2025-02-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000074', 'APP-2025-00074', '2025-02-11', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00049', 'APP-2025-00074', '2025-03-03', '2025-03-03', '2026-03-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00075', 'AP-00164', 'GF-00154', '2025-02-06', 'New', 'Approved', '2025-03-02', 'LC03', 'Mabini East', 'ACQ-89490-25', '2024-12-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00075', 1, 'Identity', 'REF-624795', '2025-02-06', 'Accepted', '2025-02-08', NULL),
('APP-2025-00075', 2, 'Registration', 'DOC-536615', '2025-02-07', 'Accepted', '2025-02-13', NULL),
('APP-2025-00075', 3, 'Acquisition', 'ACQ-89490-25', '2025-02-08', 'Accepted', '2025-02-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000075', 'APP-2025-00075', '2025-02-17', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00050', 'APP-2025-00075', '2025-03-04', '2025-03-04', '2026-03-03', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00076', 'AP-00080', 'GF-00141', '2025-02-07', 'New', 'Approved', '2025-02-27', 'LC02', 'San Isidro Heights', 'ACQ-60645-25', '2024-10-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00076', 1, 'Identity', 'FILE-571523', '2025-02-07', 'Accepted', '2025-02-11', NULL),
('APP-2025-00076', 2, 'Registration', 'REF-340813', '2025-02-11', 'Accepted', '2025-02-18', NULL),
('APP-2025-00076', 3, 'Acquisition', 'ACQ-60645-25', '2025-02-10', 'Accepted', '2025-02-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000076', 'APP-2025-00076', '2025-02-07', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00051', 'APP-2025-00076', '2025-03-01', '2025-03-01', '2026-02-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00077', 'AP-00130', 'GF-00077', '2025-02-10', 'New', 'Submitted', NULL, 'LC02', 'San Isidro Heights', 'ACQ-20000-25', '2024-12-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00077', 1, 'Identity', 'DOC-890653', '2025-02-10', 'Pending', NULL, NULL),
('APP-2025-00077', 2, 'Registration', 'REF-438590', '2025-02-11', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000077', 'APP-2025-00077', '2025-02-18', 1200, 'Cash'),
('OR-2025-000078', 'APP-2025-00077', '2025-02-16', 250, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00078', 'AP-00053', 'GF-00050', '2025-02-10', 'New', 'Approved', '2025-02-23', 'LC07', 'Pulo Verde', 'ACQ-40477-25', '2024-11-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00078', 1, 'Identity', 'FILE-232790', '2025-02-10', 'Accepted', '2025-02-11', NULL),
('APP-2025-00078', 2, 'Registration', 'DOC-545624', '2025-02-13', 'Accepted', '2025-02-20', NULL),
('APP-2025-00078', 3, 'Acquisition', 'ACQ-40477-25', '2025-02-12', 'Accepted', '2025-02-19', NULL),
('APP-2025-00078', 4, 'Other', 'DOC-855992', '2025-02-12', 'Accepted', '2025-02-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000079', 'APP-2025-00078', '2025-02-19', 450, 'BankTransfer'),
('OR-2025-000080', 'APP-2025-00078', '2025-02-16', 150, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00052', 'APP-2025-00078', '2025-02-27', '2025-02-27', '2026-02-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00079', 'AP-00063', 'GF-00059', '2025-02-10', 'New', 'Approved', '2025-02-20', 'LC02', 'San Isidro Heights', 'ACQ-68449-25', '2025-01-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00079', 1, 'Identity', 'DOC-555504', '2025-02-10', 'Accepted', '2025-02-13', NULL),
('APP-2025-00079', 2, 'Registration', 'REF-942807', '2025-02-13', 'Accepted', '2025-02-20', NULL),
('APP-2025-00079', 3, 'Acquisition', 'ACQ-68449-25', '2025-02-13', 'Accepted', '2025-02-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000081', 'APP-2025-00079', '2025-02-14', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00053', 'APP-2025-00079', '2025-02-23', '2025-02-23', '2026-02-22', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00080', 'AP-00167', 'GF-00123', '2025-02-12', 'New', 'Approved', '2025-03-04', 'LC01', 'Luntian Central', 'ACQ-65245-25', '2024-12-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00080', 1, 'Identity', 'FILE-936625', '2025-02-12', 'Accepted', '2025-02-19', NULL),
('APP-2025-00080', 2, 'Registration', 'DOC-229173', '2025-02-12', 'Accepted', '2025-02-19', NULL),
('APP-2025-00080', 3, 'Acquisition', 'ACQ-65245-25', '2025-02-12', 'Accepted', '2025-02-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000082', 'APP-2025-00080', '2025-02-19', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00054', 'APP-2025-00080', '2025-03-07', '2025-03-07', '2026-03-06', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00081', 'AP-00161', 'GF-00055', '2025-02-12', 'New', 'Approved', '2025-02-16', 'LC01', 'Luntian Central', 'ACQ-53756-25', '2025-01-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00081', 1, 'Identity', 'DOC-526064', '2025-02-12', 'Accepted', '2025-02-14', NULL),
('APP-2025-00081', 2, 'Registration', 'FILE-452126', '2025-02-14', 'Accepted', '2025-02-16', NULL),
('APP-2025-00081', 3, 'Acquisition', 'ACQ-53756-25', '2025-02-12', 'Accepted', '2025-02-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000083', 'APP-2025-00081', '2025-02-12', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00055', 'APP-2025-00081', '2025-02-16', '2025-02-16', '2026-02-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00082', 'AP-00134', 'GF-00145', '2025-02-14', 'New', 'Approved', '2025-03-04', 'LC07', 'Pulo Verde', 'ACQ-29845-25', '2024-12-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00082', 1, 'Identity', 'FILE-40851', '2025-02-14', 'Accepted', '2025-02-19', NULL),
('APP-2025-00082', 2, 'Registration', 'FILE-959990', '2025-02-14', 'Accepted', '2025-02-15', NULL),
('APP-2025-00082', 3, 'Acquisition', 'ACQ-29845-25', '2025-02-18', 'Accepted', '2025-02-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000084', 'APP-2025-00082', '2025-02-26', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00056', 'APP-2025-00082', '2025-03-09', '2025-03-09', '2026-03-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00083', 'AP-00094', 'GF-00068', '2025-02-15', 'New', 'Approved', '2025-02-28', 'LC03', 'Mabini East', 'ACQ-39343-25', '2024-11-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00083', 1, 'Identity', 'DOC-609318', '2025-02-15', 'Accepted', '2025-02-19', NULL),
('APP-2025-00083', 2, 'Registration', 'FILE-300439', '2025-02-20', 'Accepted', '2025-02-25', NULL),
('APP-2025-00083', 3, 'Acquisition', 'ACQ-39343-25', '2025-02-20', 'Accepted', '2025-02-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000085', 'APP-2025-00083', '2025-02-20', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00084', 'AP-00125', 'GF-00109', '2025-02-15', 'New', 'Approved', '2025-02-27', 'LC04', 'Bagong Silangan', 'ACQ-35625-25', '2025-02-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00084', 1, 'Identity', 'DOC-350073', '2025-02-15', 'Accepted', '2025-02-21', NULL),
('APP-2025-00084', 2, 'Registration', 'FILE-611861', '2025-02-16', 'Accepted', '2025-02-19', NULL),
('APP-2025-00084', 3, 'Acquisition', 'ACQ-35625-25', '2025-02-17', 'Accepted', '2025-02-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000086', 'APP-2025-00084', '2025-02-18', 750, 'Online'),
('OR-2025-000087', 'APP-2025-00084', '2025-02-17', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00057', 'APP-2025-00084', '2025-03-02', '2025-03-02', '2026-03-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00085', 'AP-00094', 'GF-00078', '2025-02-17', 'New', 'Approved', '2025-03-21', 'LC03', 'Mabini East', 'ACQ-22646-25', '2024-10-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00085', 1, 'Identity', 'FILE-309293', '2025-02-17', 'Accepted', '2025-02-20', NULL),
('APP-2025-00085', 2, 'Registration', 'FILE-245106', '2025-02-22', 'Accepted', '2025-02-26', NULL),
('APP-2025-00085', 3, 'Acquisition', 'ACQ-22646-25', '2025-02-17', 'Accepted', '2025-02-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000088', 'APP-2025-00085', '2025-02-27', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00058', 'APP-2025-00085', '2025-03-21', '2025-03-21', '2026-03-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00086', 'AP-00161', 'GF-00005', '2025-02-17', 'New', 'Approved', '2025-03-13', 'LC01', 'Luntian Central', 'ACQ-25960-25', '2024-10-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00086', 1, 'Identity', 'DOC-198931', '2025-02-17', 'Accepted', '2025-02-20', NULL),
('APP-2025-00086', 2, 'Registration', 'DOC-740662', '2025-02-22', 'Accepted', '2025-02-24', NULL),
('APP-2025-00086', 3, 'Acquisition', 'ACQ-25960-25', '2025-02-18', 'Accepted', '2025-02-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000089', 'APP-2025-00086', '2025-02-23', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00059', 'APP-2025-00086', '2025-03-16', '2025-03-16', '2026-03-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00087', 'AP-00010', 'GF-00073', '2025-02-18', 'New', 'Approved', '2025-03-06', 'LC07', 'Pulo Verde', 'ACQ-31627-25', '2025-01-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00087', 1, 'Identity', 'REF-811645', '2025-02-18', 'Accepted', '2025-02-25', NULL),
('APP-2025-00087', 2, 'Registration', 'FILE-799529', '2025-02-18', 'Accepted', '2025-02-22', NULL),
('APP-2025-00087', 3, 'Acquisition', 'ACQ-31627-25', '2025-02-19', 'Accepted', '2025-02-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000090', 'APP-2025-00087', '2025-02-23', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00060', 'APP-2025-00087', '2025-03-11', '2025-03-11', '2026-03-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00088', 'AP-00063', 'GF-00006', '2025-02-18', 'New', 'Approved', '2025-03-09', 'LC02', 'San Isidro Heights', 'ACQ-55230-25', '2025-01-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00088', 1, 'Identity', 'DOC-855588', '2025-02-18', 'Accepted', '2025-02-23', NULL),
('APP-2025-00088', 2, 'Registration', 'FILE-916853', '2025-02-20', 'Accepted', '2025-02-24', NULL),
('APP-2025-00088', 3, 'Acquisition', 'ACQ-55230-25', '2025-02-22', 'Accepted', '2025-02-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000091', 'APP-2025-00088', '2025-02-28', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00061', 'APP-2025-00088', '2025-03-11', '2025-03-11', '2026-03-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00089', 'AP-00131', 'GF-00092', '2025-02-19', 'New', 'Rejected', '2025-03-06', 'LC05', 'Santa Elena', 'ACQ-99591-25', '2024-10-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00089', 1, 'Identity', 'DOC-701725', '2025-02-19', 'Accepted', '2025-02-24', NULL),
('APP-2025-00089', 2, 'Registration', 'DOC-429160', '2025-02-22', 'Accepted', '2025-02-23', NULL),
('APP-2025-00089', 3, 'Acquisition', 'ACQ-99591-25', '2025-02-19', 'Accepted', '2025-02-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000092', 'APP-2025-00089', '2025-02-19', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00090', 'AP-00031', 'GF-00157', '2025-02-21', 'New', 'Submitted', NULL, 'LC04', 'Bagong Silangan', 'ACQ-71184-25', '2025-01-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00090', 1, 'Identity', 'DOC-528866', '2025-02-21', 'Pending', NULL, NULL),
('APP-2025-00090', 2, 'Registration', 'DOC-667163', '2025-02-22', 'Pending', NULL, NULL),
('APP-2025-00090', 3, 'Acquisition', 'ACQ-71184-25', '2025-02-25', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000093', 'APP-2025-00090', '2025-03-05', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00091', 'AP-00094', 'GF-00049', '2025-02-23', 'New', 'Withdrawn', NULL, 'LC03', 'Mabini East', 'ACQ-68989-25', '2024-12-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00091', 1, 'Identity', 'DOC-56457', '2025-02-23', 'Accepted', '2025-02-25', NULL),
('APP-2025-00091', 2, 'Registration', 'DOC-848952', '2025-02-24', 'Accepted', '2025-03-01', NULL),
('APP-2025-00091', 3, 'Acquisition', 'ACQ-68989-25', '2025-02-25', 'NeedsCorrection', '2025-03-02', 'Please provide the missing page of the supporting document.'),
('APP-2025-00091', 4, 'Other', 'DOC-199691', '2025-02-26', 'Accepted', '2025-03-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000094', 'APP-2025-00091', '2025-02-27', 750, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00092', 'AP-00150', 'GF-00070', '2025-02-23', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-78865-25', '2025-02-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00092', 1, 'Identity', 'FILE-542589', '2025-02-23', 'Pending', NULL, NULL),
('APP-2025-00092', 2, 'Registration', 'REF-675167', '2025-02-26', 'NeedsCorrection', '2025-02-28', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00092', 3, 'Acquisition', 'ACQ-78865-25', '2025-02-28', 'Accepted', '2025-03-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000095', 'APP-2025-00092', '2025-02-25', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00093', 'AP-00121', 'GF-00136', '2025-02-24', 'New', 'Withdrawn', NULL, 'LC02', 'San Isidro Heights', 'ACQ-70890-25', '2024-12-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00093', 1, 'Identity', 'FILE-150340', '2025-02-24', 'Pending', NULL, NULL),
('APP-2025-00093', 2, 'Registration', 'DOC-361275', '2025-02-26', 'Accepted', '2025-03-04', NULL),
('APP-2025-00093', 3, 'Acquisition', 'ACQ-70890-25', '2025-02-27', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000096', 'APP-2025-00093', '2025-02-24', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00094', 'AP-00117', 'GF-00012', '2025-02-27', 'New', 'Approved', '2025-03-10', 'LC04', 'Bagong Silangan', 'ACQ-62100-25', '2025-02-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00094', 1, 'Identity', 'REF-810896', '2025-02-27', 'Accepted', '2025-03-06', NULL),
('APP-2025-00094', 2, 'Registration', 'FILE-381677', '2025-02-28', 'Accepted', '2025-03-03', NULL),
('APP-2025-00094', 3, 'Acquisition', 'ACQ-62100-25', '2025-02-28', 'Accepted', '2025-03-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000097', 'APP-2025-00094', '2025-03-05', 1200, 'Online'),
('OR-2025-000098', 'APP-2025-00094', '2025-03-07', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00062', 'APP-2025-00094', '2025-03-10', '2025-03-10', '2026-03-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00095', 'AP-00125', 'GF-00147', '2025-02-27', 'New', 'Approved', '2025-03-14', 'LC04', 'Bagong Silangan', 'ACQ-35812-25', '2024-12-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00095', 1, 'Identity', 'DOC-327970', '2025-02-27', 'Accepted', '2025-03-04', NULL),
('APP-2025-00095', 2, 'Registration', 'DOC-527066', '2025-02-27', 'Accepted', '2025-03-01', NULL),
('APP-2025-00095', 3, 'Acquisition', 'ACQ-35812-25', '2025-02-27', 'Accepted', '2025-03-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000099', 'APP-2025-00095', '2025-03-11', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00063', 'APP-2025-00095', '2025-03-15', '2025-03-15', '2026-03-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00096', 'AP-00149', 'GF-00081', '2025-02-27', 'New', 'UnderReview', NULL, 'LC01', 'Luntian Central', 'ACQ-34539-25', '2025-02-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00096', 1, 'Identity', 'DOC-981691', '2025-02-27', 'NeedsCorrection', '2025-03-02', 'Please provide the missing page of the supporting document.'),
('APP-2025-00096', 2, 'Registration', 'REF-96775', '2025-03-03', 'Accepted', '2025-03-07', NULL),
('APP-2025-00096', 3, 'Acquisition', 'ACQ-34539-25', '2025-02-27', 'Accepted', '2025-03-02', NULL),
('APP-2025-00096', 4, 'Other', 'FILE-820779', '2025-02-28', 'Accepted', '2025-03-02', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00097', 'AP-00078', 'GF-00037', '2025-03-01', 'New', 'Approved', '2025-03-09', 'LC03', 'Mabini East', 'ACQ-83548-25', '2025-01-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00097', 1, 'Identity', 'REF-175765', '2025-03-01', 'Accepted', '2025-03-04', NULL),
('APP-2025-00097', 2, 'Registration', 'FILE-696348', '2025-03-04', 'Accepted', '2025-03-08', NULL),
('APP-2025-00097', 3, 'Acquisition', 'ACQ-83548-25', '2025-03-04', 'Accepted', '2025-03-06', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00064', 'APP-2025-00097', '2025-03-11', '2025-03-11', '2026-03-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00098', 'AP-00123', 'GF-00078', '2025-03-02', 'New', 'Approved', '2025-04-23', 'LC01', 'Luntian Central', 'ACQ-74520-25', '2025-01-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00098', 1, 'Identity', 'REF-522203', '2025-03-02', 'Accepted', '2025-03-04', NULL),
('APP-2025-00098', 2, 'Registration', 'DOC-339765', '2025-03-05', 'Accepted', '2025-03-06', NULL),
('APP-2025-00098', 3, 'Acquisition', 'ACQ-74520-25', '2025-03-06', 'Accepted', '2025-03-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000100', 'APP-2025-00098', '2025-03-05', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00065', 'APP-2025-00098', '2025-04-28', '2025-04-28', '2026-04-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00099', 'AP-00156', 'GF-00110', '2025-03-02', 'New', 'UnderReview', NULL, 'LC06', 'Maligaya', 'ACQ-75875-25', '2024-12-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00099', 1, 'Identity', 'DOC-815363', '2025-03-02', 'Accepted', '2025-03-06', NULL),
('APP-2025-00099', 2, 'Registration', 'DOC-333026', '2025-03-06', 'Accepted', '2025-03-10', NULL),
('APP-2025-00099', 3, 'Acquisition', 'ACQ-75875-25', '2025-03-07', 'Accepted', '2025-03-13', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00100', 'AP-00023', 'GF-00012', '2025-03-04', 'New', 'Approved', '2025-03-29', 'LC04', 'Bagong Silangan', 'ACQ-70198-25', '2024-12-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00100', 1, 'Identity', 'FILE-591919', '2025-03-04', 'Accepted', '2025-03-07', NULL),
('APP-2025-00100', 2, 'Registration', 'DOC-512807', '2025-03-06', 'Accepted', '2025-03-13', NULL),
('APP-2025-00100', 3, 'Acquisition', 'ACQ-70198-25', '2025-03-05', 'Accepted', '2025-03-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000101', 'APP-2025-00100', '2025-03-07', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00101', 'AP-00126', 'GF-00119', '2025-03-05', 'New', 'Approved', '2025-03-27', 'LC05', 'Santa Elena', 'ACQ-90737-25', '2024-11-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00101', 1, 'Identity', 'FILE-340608', '2025-03-05', 'Accepted', '2025-03-09', NULL),
('APP-2025-00101', 2, 'Registration', 'DOC-750502', '2025-03-09', 'Accepted', '2025-03-12', NULL),
('APP-2025-00101', 3, 'Acquisition', 'ACQ-90737-25', '2025-03-09', 'Accepted', '2025-03-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000102', 'APP-2025-00101', '2025-03-12', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00066', 'APP-2025-00101', '2025-03-31', '2025-03-31', '2026-03-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00102', 'AP-00064', 'GF-00150', '2025-03-06', 'New', 'Withdrawn', NULL, 'LC07', 'Pulo Verde', 'ACQ-18138-25', '2025-01-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00102', 1, 'Identity', 'REF-240330', '2025-03-06', 'Accepted', '2025-03-11', NULL),
('APP-2025-00102', 2, 'Registration', 'DOC-757210', '2025-03-07', 'Accepted', '2025-03-14', NULL),
('APP-2025-00102', 3, 'Acquisition', 'ACQ-18138-25', '2025-03-08', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000103', 'APP-2025-00102', '2025-03-13', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00103', 'AP-00110', 'GF-00120', '2025-03-07', 'New', 'Approved', '2025-04-01', 'LC04', 'Bagong Silangan', 'ACQ-93822-25', '2025-01-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00103', 1, 'Identity', 'REF-849520', '2025-03-07', 'Accepted', '2025-03-11', NULL),
('APP-2025-00103', 2, 'Registration', 'DOC-231380', '2025-03-09', 'Accepted', '2025-03-14', NULL),
('APP-2025-00103', 3, 'Acquisition', 'ACQ-93822-25', '2025-03-11', 'Accepted', '2025-03-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000104', 'APP-2025-00103', '2025-03-07', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00067', 'APP-2025-00103', '2025-04-03', '2025-04-03', '2026-04-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00104', 'AP-00016', 'GF-00057', '2025-03-08', 'New', 'Approved', '2025-03-26', 'LC06', 'Maligaya', 'ACQ-38282-25', '2024-12-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00104', 1, 'Identity', 'REF-317033', '2025-03-08', 'Accepted', '2025-03-15', NULL),
('APP-2025-00104', 2, 'Registration', 'FILE-826260', '2025-03-09', 'Accepted', '2025-03-14', NULL),
('APP-2025-00104', 3, 'Acquisition', 'ACQ-38282-25', '2025-03-11', 'Accepted', '2025-03-12', NULL),
('APP-2025-00104', 4, 'Other', 'FILE-657932', '2025-03-09', 'Accepted', '2025-03-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000105', 'APP-2025-00104', '2025-03-20', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00068', 'APP-2025-00104', '2025-03-31', '2025-03-31', '2026-03-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00105', 'AP-00005', 'GF-00086', '2025-03-08', 'New', 'Approved', '2025-03-19', 'LC03', 'Mabini East', 'ACQ-53097-25', '2024-12-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00105', 1, 'Identity', 'FILE-191938', '2025-03-08', 'Accepted', '2025-03-09', NULL),
('APP-2025-00105', 2, 'Registration', 'REF-936144', '2025-03-13', 'Accepted', '2025-03-19', NULL),
('APP-2025-00105', 3, 'Acquisition', 'ACQ-53097-25', '2025-03-09', 'Accepted', '2025-03-15', NULL),
('APP-2025-00105', 4, 'Other', 'FILE-171497', '2025-03-13', 'Accepted', '2025-03-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000106', 'APP-2025-00105', '2025-03-09', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00069', 'APP-2025-00105', '2025-03-23', '2025-03-23', '2026-03-22', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00106', 'AP-00082', 'GF-00081', '2025-03-10', 'New', 'Approved', '2025-05-05', 'LC07', 'Pulo Verde', 'ACQ-89236-25', '2025-03-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00106', 1, 'Identity', 'FILE-459748', '2025-03-10', 'Accepted', '2025-03-13', NULL),
('APP-2025-00106', 2, 'Registration', 'DOC-774575', '2025-03-11', 'Accepted', '2025-03-12', NULL),
('APP-2025-00106', 3, 'Acquisition', 'ACQ-89236-25', '2025-03-12', 'Accepted', '2025-03-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000107', 'APP-2025-00106', '2025-03-11', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00070', 'APP-2025-00106', '2025-05-08', '2025-05-08', '2026-05-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00107', 'AP-00120', 'GF-00053', '2025-03-13', 'New', 'Approved', '2025-03-28', 'LC02', 'San Isidro Heights', 'ACQ-17607-25', '2025-02-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00107', 1, 'Identity', 'DOC-871443', '2025-03-13', 'Accepted', '2025-03-16', NULL),
('APP-2025-00107', 2, 'Registration', 'DOC-376900', '2025-03-17', 'Accepted', '2025-03-20', NULL),
('APP-2025-00107', 3, 'Acquisition', 'ACQ-17607-25', '2025-03-17', 'Accepted', '2025-03-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000108', 'APP-2025-00107', '2025-03-25', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00071', 'APP-2025-00107', '2025-04-01', '2025-04-01', '2026-03-31', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00108', 'AP-00011', 'GF-00075', '2025-03-14', 'New', 'Rejected', '2025-03-28', 'LC03', 'Mabini East', 'ACQ-62007-25', '2025-02-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00108', 1, 'Identity', 'FILE-919062', '2025-03-14', 'Pending', NULL, NULL),
('APP-2025-00108', 2, 'Registration', 'FILE-296387', '2025-03-16', 'Accepted', '2025-03-19', NULL),
('APP-2025-00108', 3, 'Acquisition', 'ACQ-62007-25', '2025-03-18', 'Accepted', '2025-03-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000109', 'APP-2025-00108', '2025-03-17', 900, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00109', 'AP-00046', 'GF-00137', '2025-03-16', 'New', 'Approved', '2025-03-21', 'LC02', 'San Isidro Heights', 'ACQ-49856-25', '2024-12-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00109', 1, 'Identity', 'FILE-505421', '2025-03-16', 'Accepted', '2025-03-21', NULL),
('APP-2025-00109', 2, 'Registration', 'REF-640382', '2025-03-18', 'Accepted', '2025-03-21', NULL),
('APP-2025-00109', 3, 'Acquisition', 'ACQ-49856-25', '2025-03-21', 'Accepted', '2025-03-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000110', 'APP-2025-00109', '2025-03-20', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00072', 'APP-2025-00109', '2025-03-21', '2025-03-21', '2026-03-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00110', 'AP-00069', 'GF-00139', '2025-03-17', 'New', 'Approved', '2025-03-25', 'LC01', 'Luntian Central', 'ACQ-10066-25', '2025-01-05', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00110', 1, 'Identity', 'REF-735973', '2025-03-17', 'Accepted', '2025-03-22', NULL),
('APP-2025-00110', 2, 'Registration', 'DOC-720769', '2025-03-20', 'Accepted', '2025-03-22', NULL),
('APP-2025-00110', 3, 'Acquisition', 'ACQ-10066-25', '2025-03-20', 'Accepted', '2025-03-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000111', 'APP-2025-00110', '2025-03-25', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00073', 'APP-2025-00110', '2025-03-28', '2025-03-28', '2026-03-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00111', 'AP-00094', 'GF-00011', '2025-03-17', 'New', 'Approved', '2025-04-02', 'LC03', 'Mabini East', 'ACQ-17931-25', '2025-01-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00111', 1, 'Identity', 'FILE-992686', '2025-03-17', 'Accepted', '2025-03-20', NULL),
('APP-2025-00111', 2, 'Registration', 'DOC-714561', '2025-03-22', 'Accepted', '2025-03-28', NULL),
('APP-2025-00111', 3, 'Acquisition', 'ACQ-17931-25', '2025-03-18', 'Accepted', '2025-03-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000112', 'APP-2025-00111', '2025-03-23', 900, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00112', 'AP-00126', 'GF-00010', '2025-03-17', 'New', 'Approved', '2025-04-03', 'LC05', 'Santa Elena', 'ACQ-39124-25', '2025-01-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00112', 1, 'Identity', 'REF-343523', '2025-03-17', 'Accepted', '2025-03-22', NULL),
('APP-2025-00112', 2, 'Registration', 'FILE-379686', '2025-03-17', 'Accepted', '2025-03-19', NULL),
('APP-2025-00112', 3, 'Acquisition', 'ACQ-39124-25', '2025-03-17', 'Accepted', '2025-03-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000113', 'APP-2025-00112', '2025-03-24', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00113', 'AP-00068', 'GF-00024', '2025-03-18', 'New', 'Approved', '2025-04-16', 'LC02', 'San Isidro Heights', 'ACQ-40062-25', '2024-12-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00113', 1, 'Identity', 'FILE-335366', '2025-03-18', 'Accepted', '2025-03-21', NULL),
('APP-2025-00113', 2, 'Registration', 'FILE-317323', '2025-03-19', 'Accepted', '2025-03-22', NULL),
('APP-2025-00113', 3, 'Acquisition', 'ACQ-40062-25', '2025-03-19', 'Accepted', '2025-03-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000114', 'APP-2025-00113', '2025-03-26', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00074', 'APP-2025-00113', '2025-04-16', '2025-04-16', '2026-04-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00114', 'AP-00102', 'GF-00146', '2025-03-18', 'New', 'Approved', '2025-05-11', 'LC03', 'Mabini East', 'ACQ-13885-25', '2024-11-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00114', 1, 'Identity', 'REF-469674', '2025-03-18', 'Accepted', '2025-03-21', NULL),
('APP-2025-00114', 2, 'Registration', 'DOC-12212', '2025-03-22', 'Accepted', '2025-03-24', NULL),
('APP-2025-00114', 3, 'Acquisition', 'ACQ-13885-25', '2025-03-21', 'Accepted', '2025-03-25', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00075', 'APP-2025-00114', '2025-05-15', '2025-05-15', '2026-05-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00115', 'AP-00071', 'GF-00136', '2025-03-19', 'New', 'Approved', '2025-04-02', 'LC07', 'Pulo Verde', 'ACQ-92964-25', '2025-01-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00115', 1, 'Identity', 'REF-620736', '2025-03-19', 'Accepted', '2025-03-26', NULL),
('APP-2025-00115', 2, 'Registration', 'FILE-120143', '2025-03-23', 'Accepted', '2025-03-25', NULL),
('APP-2025-00115', 3, 'Acquisition', 'ACQ-92964-25', '2025-03-23', 'Accepted', '2025-03-28', NULL),
('APP-2025-00115', 4, 'Other', 'DOC-479756', '2025-03-23', 'Accepted', '2025-03-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000115', 'APP-2025-00115', '2025-03-28', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00076', 'APP-2025-00115', '2025-04-05', '2025-04-05', '2026-04-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00116', 'AP-00121', 'GF-00132', '2025-03-19', 'New', 'Approved', '2025-04-08', 'LC02', 'San Isidro Heights', 'ACQ-28959-25', '2025-01-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00116', 1, 'Identity', 'REF-673306', '2025-03-19', 'Accepted', '2025-03-22', NULL),
('APP-2025-00116', 2, 'Registration', 'REF-552475', '2025-03-22', 'Accepted', '2025-03-25', NULL),
('APP-2025-00116', 3, 'Acquisition', 'ACQ-28959-25', '2025-03-21', 'Accepted', '2025-03-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000116', 'APP-2025-00116', '2025-03-31', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00077', 'APP-2025-00116', '2025-04-11', '2025-04-11', '2026-04-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00117', 'AP-00023', 'GF-00136', '2025-03-22', 'New', 'Rejected', '2025-04-01', 'LC04', 'Bagong Silangan', 'ACQ-28750-25', '2025-03-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00117', 1, 'Identity', 'DOC-722372', '2025-03-22', 'Accepted', '2025-03-27', NULL),
('APP-2025-00117', 2, 'Registration', 'DOC-952785', '2025-03-25', 'Accepted', '2025-03-26', NULL),
('APP-2025-00117', 3, 'Acquisition', 'ACQ-28750-25', '2025-03-27', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000117', 'APP-2025-00117', '2025-04-01', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00118', 'AP-00123', 'GF-00048', '2025-03-23', 'New', 'Approved', '2025-04-08', 'LC01', 'Luntian Central', 'ACQ-16571-25', '2025-03-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00118', 1, 'Identity', 'FILE-869909', '2025-03-23', 'Accepted', '2025-03-28', NULL),
('APP-2025-00118', 2, 'Registration', 'FILE-899087', '2025-03-24', 'Accepted', '2025-03-28', NULL),
('APP-2025-00118', 3, 'Acquisition', 'ACQ-16571-25', '2025-03-25', 'Accepted', '2025-03-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000118', 'APP-2025-00118', '2025-03-30', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00078', 'APP-2025-00118', '2025-04-11', '2025-04-11', '2026-04-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00119', 'AP-00058', 'GF-00029', '2025-03-24', 'New', 'Approved', '2025-04-14', 'LC03', 'Mabini East', 'ACQ-24040-25', '2024-12-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00119', 1, 'Identity', 'REF-876547', '2025-03-24', 'Accepted', '2025-03-29', NULL),
('APP-2025-00119', 2, 'Registration', 'REF-195638', '2025-03-28', 'Accepted', '2025-04-01', NULL),
('APP-2025-00119', 3, 'Acquisition', 'ACQ-24040-25', '2025-03-28', 'Accepted', '2025-04-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000119', 'APP-2025-00119', '2025-03-27', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00120', 'AP-00048', 'GF-00013', '2025-03-24', 'New', 'Approved', '2025-03-27', 'LC03', 'Mabini East', 'ACQ-96853-25', '2025-02-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00120', 1, 'Identity', 'FILE-833359', '2025-03-24', 'Accepted', '2025-03-26', NULL),
('APP-2025-00120', 2, 'Registration', 'FILE-314064', '2025-03-24', 'Accepted', '2025-03-26', NULL),
('APP-2025-00120', 3, 'Acquisition', 'ACQ-96853-25', '2025-03-27', 'Accepted', '2025-03-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000120', 'APP-2025-00120', '2025-03-27', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00079', 'APP-2025-00120', '2025-03-27', '2025-03-27', '2026-03-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00121', 'AP-00004', 'GF-00142', '2025-03-24', 'New', 'Approved', '2025-04-02', 'LC01', 'Luntian Central', 'ACQ-77650-25', '2025-02-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00121', 1, 'Identity', 'DOC-477373', '2025-03-24', 'Accepted', '2025-03-28', NULL),
('APP-2025-00121', 2, 'Registration', 'DOC-956653', '2025-03-26', 'Accepted', '2025-04-02', NULL),
('APP-2025-00121', 3, 'Acquisition', 'ACQ-77650-25', '2025-03-26', 'Accepted', '2025-03-28', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00080', 'APP-2025-00121', '2025-04-03', '2025-04-03', '2026-04-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00122', 'AP-00046', 'GF-00007', '2025-03-24', 'New', 'Approved', '2025-03-31', 'LC02', 'San Isidro Heights', 'ACQ-63384-25', '2024-12-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00122', 1, 'Identity', 'FILE-222501', '2025-03-24', 'Accepted', '2025-03-30', NULL),
('APP-2025-00122', 2, 'Registration', 'REF-70993', '2025-03-27', 'Accepted', '2025-03-31', NULL),
('APP-2025-00122', 3, 'Acquisition', 'ACQ-63384-25', '2025-03-27', 'Accepted', '2025-03-31', NULL),
('APP-2025-00122', 4, 'Other', 'DOC-974828', '2025-03-25', 'Accepted', '2025-03-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000121', 'APP-2025-00122', '2025-03-30', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00081', 'APP-2025-00122', '2025-04-05', '2025-04-05', '2026-04-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00123', 'AP-00051', 'GF-00161', '2025-03-25', 'New', 'Approved', '2025-04-11', 'LC02', 'San Isidro Heights', 'ACQ-88402-25', '2024-12-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00123', 1, 'Identity', 'FILE-485659', '2025-03-25', 'Accepted', '2025-03-27', NULL),
('APP-2025-00123', 2, 'Registration', 'DOC-160742', '2025-03-30', 'Accepted', '2025-04-02', NULL),
('APP-2025-00123', 3, 'Acquisition', 'ACQ-88402-25', '2025-03-28', 'Accepted', '2025-03-31', NULL),
('APP-2025-00123', 4, 'Other', 'REF-526110', '2025-03-27', 'Accepted', '2025-03-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000122', 'APP-2025-00123', '2025-04-06', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00082', 'APP-2025-00123', '2025-04-11', '2025-04-11', '2026-04-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00124', 'AP-00141', 'GF-00150', '2025-03-27', 'New', 'Approved', '2025-05-01', 'LC02', 'San Isidro Heights', 'ACQ-67232-25', '2024-12-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00124', 1, 'Identity', 'DOC-448788', '2025-03-27', 'Accepted', '2025-03-30', NULL),
('APP-2025-00124', 2, 'Registration', 'DOC-472839', '2025-04-01', 'Accepted', '2025-04-02', NULL),
('APP-2025-00124', 3, 'Acquisition', 'ACQ-67232-25', '2025-03-29', 'Accepted', '2025-03-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000123', 'APP-2025-00124', '2025-04-08', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00083', 'APP-2025-00124', '2025-05-06', '2025-05-06', '2026-05-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00125', 'AP-00013', 'GF-00101', '2025-03-28', 'New', 'Approved', '2025-05-03', 'LC06', 'Maligaya', 'ACQ-84311-25', '2025-02-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00125', 1, 'Identity', 'REF-509575', '2025-03-28', 'Accepted', '2025-03-30', NULL),
('APP-2025-00125', 2, 'Registration', 'REF-185977', '2025-03-31', 'Accepted', '2025-04-06', NULL),
('APP-2025-00125', 3, 'Acquisition', 'ACQ-84311-25', '2025-03-31', 'Accepted', '2025-04-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000124', 'APP-2025-00125', '2025-03-29', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00084', 'APP-2025-00125', '2025-05-08', '2025-05-08', '2026-05-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00126', 'AP-00084', 'GF-00042', '2025-03-29', 'New', 'Approved', '2025-04-09', 'LC03', 'Mabini East', 'ACQ-63829-25', '2025-02-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00126', 1, 'Identity', 'DOC-772720', '2025-03-29', 'Accepted', '2025-04-05', NULL),
('APP-2025-00126', 2, 'Registration', 'DOC-622642', '2025-03-31', 'Accepted', '2025-04-01', NULL),
('APP-2025-00126', 3, 'Acquisition', 'ACQ-63829-25', '2025-03-31', 'Accepted', '2025-04-06', NULL),
('APP-2025-00126', 4, 'Other', 'REF-616179', '2025-04-03', 'Accepted', '2025-04-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000125', 'APP-2025-00126', '2025-04-07', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00085', 'APP-2025-00126', '2025-04-13', '2025-04-13', '2026-04-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00127', 'AP-00112', 'GF-00165', '2025-03-29', 'New', 'Approved', '2025-05-05', 'LC07', 'Pulo Verde', 'ACQ-61977-25', '2025-02-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00127', 1, 'Identity', 'DOC-686179', '2025-03-29', 'Accepted', '2025-04-02', NULL),
('APP-2025-00127', 2, 'Registration', 'DOC-787025', '2025-04-01', 'Accepted', '2025-04-06', NULL),
('APP-2025-00127', 3, 'Acquisition', 'ACQ-61977-25', '2025-04-03', 'Accepted', '2025-04-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000126', 'APP-2025-00127', '2025-04-05', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00086', 'APP-2025-00127', '2025-05-08', '2025-05-08', '2026-05-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00128', 'AP-00027', 'GF-00017', '2025-03-30', 'New', 'Approved', '2025-04-20', 'LC03', 'Mabini East', 'ACQ-92178-25', '2025-02-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00128', 1, 'Identity', 'REF-337410', '2025-03-30', 'Accepted', '2025-04-02', NULL),
('APP-2025-00128', 2, 'Registration', 'DOC-723861', '2025-03-31', 'Accepted', '2025-04-01', NULL),
('APP-2025-00128', 3, 'Acquisition', 'ACQ-92178-25', '2025-04-03', 'Accepted', '2025-04-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000127', 'APP-2025-00128', '2025-04-03', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00087', 'APP-2025-00128', '2025-04-25', '2025-04-25', '2026-04-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00129', 'AP-00110', 'GF-00031', '2025-03-30', 'New', 'Rejected', '2025-04-03', 'LC04', 'Bagong Silangan', 'ACQ-77302-25', '2025-03-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00129', 1, 'Identity', 'DOC-801296', '2025-03-30', 'Pending', NULL, NULL),
('APP-2025-00129', 2, 'Registration', 'REF-31376', '2025-03-30', 'NeedsCorrection', '2025-04-02', 'The date on the document needs clarification.'),
('APP-2025-00129', 3, 'Acquisition', 'ACQ-77302-25', '2025-04-03', 'Accepted', '2025-04-03', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00130', 'AP-00136', 'GF-00087', '2025-03-31', 'New', 'Approved', '2025-04-09', 'LC02', 'San Isidro Heights', 'ACQ-92548-25', '2025-02-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00130', 1, 'Identity', 'FILE-713574', '2025-03-31', 'Accepted', '2025-04-01', NULL),
('APP-2025-00130', 2, 'Registration', 'FILE-928309', '2025-04-03', 'Accepted', '2025-04-06', NULL),
('APP-2025-00130', 3, 'Acquisition', 'ACQ-92548-25', '2025-04-02', 'Accepted', '2025-04-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000128', 'APP-2025-00130', '2025-04-01', 1200, 'Cash'),
('OR-2025-000129', 'APP-2025-00130', '2025-04-06', 250, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00088', 'APP-2025-00130', '2025-04-14', '2025-04-14', '2026-04-13', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00131', 'AP-00164', 'GF-00019', '2025-03-31', 'New', 'Approved', '2025-04-15', 'LC04', 'Bagong Silangan', 'ACQ-15416-25', '2025-03-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00131', 1, 'Identity', 'FILE-444582', '2025-03-31', 'Accepted', '2025-04-02', NULL),
('APP-2025-00131', 2, 'Registration', 'REF-19879', '2025-04-03', 'Accepted', '2025-04-08', NULL),
('APP-2025-00131', 3, 'Acquisition', 'ACQ-15416-25', '2025-04-04', 'Accepted', '2025-04-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000130', 'APP-2025-00131', '2025-04-02', 600, 'BankTransfer'),
('OR-2025-000131', 'APP-2025-00131', '2025-04-12', 250, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00132', 'AP-00091', 'GF-00027', '2025-04-01', 'New', 'Rejected', '2025-04-20', 'LC02', 'San Isidro Heights', 'ACQ-69603-25', '2024-12-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00132', 1, 'Identity', 'FILE-653979', '2025-04-01', 'Accepted', '2025-04-03', NULL),
('APP-2025-00132', 2, 'Registration', 'FILE-113415', '2025-04-05', 'Pending', NULL, NULL),
('APP-2025-00132', 3, 'Acquisition', 'ACQ-69603-25', '2025-04-01', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000132', 'APP-2025-00132', '2025-04-08', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00133', 'AP-00062', 'GF-00029', '2025-04-01', 'New', 'Approved', '2025-04-20', 'LC02', 'San Isidro Heights', 'ACQ-34257-25', '2024-12-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00133', 1, 'Identity', 'DOC-312490', '2025-04-01', 'Accepted', '2025-04-07', NULL),
('APP-2025-00133', 2, 'Registration', 'DOC-799973', '2025-04-05', 'Accepted', '2025-04-11', NULL),
('APP-2025-00133', 3, 'Acquisition', 'ACQ-34257-25', '2025-04-03', 'Accepted', '2025-04-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000133', 'APP-2025-00133', '2025-04-11', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00089', 'APP-2025-00133', '2025-04-20', '2025-04-20', '2026-04-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00134', 'AP-00041', 'GF-00141', '2025-04-03', 'New', 'Approved', '2025-04-27', 'LC05', 'Santa Elena', 'ACQ-85016-25', '2024-12-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00134', 1, 'Identity', 'DOC-222940', '2025-04-03', 'Accepted', '2025-04-09', NULL),
('APP-2025-00134', 2, 'Registration', 'FILE-893082', '2025-04-08', 'Accepted', '2025-04-11', NULL),
('APP-2025-00134', 3, 'Acquisition', 'ACQ-85016-25', '2025-04-05', 'Accepted', '2025-04-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000134', 'APP-2025-00134', '2025-04-14', 450, 'Online'),
('OR-2025-000135', 'APP-2025-00134', '2025-04-13', 250, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00090', 'APP-2025-00134', '2025-04-28', '2025-04-28', '2026-04-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00135', 'AP-00172', 'GF-00154', '2025-04-04', 'New', 'Approved', '2025-04-13', 'LC06', 'Maligaya', 'ACQ-18148-25', '2025-03-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00135', 1, 'Identity', 'FILE-939539', '2025-04-04', 'Accepted', '2025-04-06', NULL),
('APP-2025-00135', 2, 'Registration', 'FILE-412646', '2025-04-08', 'Accepted', '2025-04-11', NULL),
('APP-2025-00135', 3, 'Acquisition', 'ACQ-18148-25', '2025-04-07', 'Accepted', '2025-04-11', NULL),
('APP-2025-00135', 4, 'Other', 'REF-96968', '2025-04-06', 'Accepted', '2025-04-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000136', 'APP-2025-00135', '2025-04-13', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00091', 'APP-2025-00135', '2025-04-14', '2025-04-14', '2026-04-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00136', 'AP-00116', 'GF-00097', '2025-04-05', 'New', 'Approved', '2025-05-26', 'LC04', 'Bagong Silangan', 'ACQ-12812-25', '2025-01-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00136', 1, 'Identity', 'DOC-624329', '2025-04-05', 'Accepted', '2025-04-11', NULL),
('APP-2025-00136', 2, 'Registration', 'REF-884420', '2025-04-10', 'Accepted', '2025-04-14', NULL),
('APP-2025-00136', 3, 'Acquisition', 'ACQ-12812-25', '2025-04-09', 'Accepted', '2025-04-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000137', 'APP-2025-00136', '2025-04-15', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00092', 'APP-2025-00136', '2025-05-28', '2025-05-28', '2026-05-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00137', 'AP-00015', 'GF-00130', '2025-04-05', 'New', 'Approved', '2025-04-21', 'LC03', 'Mabini East', 'ACQ-33441-25', '2025-03-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00137', 1, 'Identity', 'FILE-883838', '2025-04-05', 'Accepted', '2025-04-09', NULL),
('APP-2025-00137', 2, 'Registration', 'REF-235179', '2025-04-05', 'Accepted', '2025-04-11', NULL),
('APP-2025-00137', 3, 'Acquisition', 'ACQ-33441-25', '2025-04-08', 'Accepted', '2025-04-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000138', 'APP-2025-00137', '2025-04-07', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00093', 'APP-2025-00137', '2025-04-21', '2025-04-21', '2026-04-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00138', 'AP-00070', 'GF-00052', '2025-04-05', 'New', 'Approved', '2025-04-11', 'LC01', 'Luntian Central', 'ACQ-33983-25', '2025-01-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00138', 1, 'Identity', 'FILE-457100', '2025-04-05', 'Accepted', '2025-04-09', NULL),
('APP-2025-00138', 2, 'Registration', 'FILE-738263', '2025-04-09', 'Accepted', '2025-04-11', NULL),
('APP-2025-00138', 3, 'Acquisition', 'ACQ-33983-25', '2025-04-08', 'Accepted', '2025-04-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000139', 'APP-2025-00138', '2025-04-11', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00094', 'APP-2025-00138', '2025-04-13', '2025-04-13', '2026-04-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00139', 'AP-00006', 'GF-00029', '2025-04-06', 'New', 'Approved', '2025-04-09', 'LC03', 'Mabini East', 'ACQ-43922-25', '2025-03-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00139', 1, 'Identity', 'REF-316849', '2025-04-06', 'Accepted', '2025-04-09', NULL),
('APP-2025-00139', 2, 'Registration', 'REF-874477', '2025-04-07', 'Accepted', '2025-04-09', NULL),
('APP-2025-00139', 3, 'Acquisition', 'ACQ-43922-25', '2025-04-09', 'Accepted', '2025-04-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000140', 'APP-2025-00139', '2025-04-09', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00095', 'APP-2025-00139', '2025-04-12', '2025-04-12', '2026-04-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00140', 'AP-00165', 'GF-00121', '2025-04-07', 'New', 'Approved', '2025-04-16', 'LC07', 'Pulo Verde', 'ACQ-79892-25', '2025-02-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00140', 1, 'Identity', 'FILE-65910', '2025-04-07', 'Accepted', '2025-04-14', NULL),
('APP-2025-00140', 2, 'Registration', 'REF-758768', '2025-04-11', 'Accepted', '2025-04-16', NULL),
('APP-2025-00140', 3, 'Acquisition', 'ACQ-79892-25', '2025-04-10', 'Accepted', '2025-04-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000141', 'APP-2025-00140', '2025-04-16', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00096', 'APP-2025-00140', '2025-04-19', '2025-04-19', '2026-04-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00141', 'AP-00024', 'GF-00088', '2025-04-11', 'New', 'Approved', '2025-04-21', 'LC07', 'Pulo Verde', 'ACQ-83762-25', '2025-01-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00141', 1, 'Identity', 'DOC-162384', '2025-04-11', 'Accepted', '2025-04-17', NULL),
('APP-2025-00141', 2, 'Registration', 'REF-301910', '2025-04-12', 'Accepted', '2025-04-19', NULL),
('APP-2025-00141', 3, 'Acquisition', 'ACQ-83762-25', '2025-04-15', 'Accepted', '2025-04-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000142', 'APP-2025-00141', '2025-04-13', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00097', 'APP-2025-00141', '2025-04-23', '2025-04-23', '2026-04-22', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00142', 'AP-00009', 'GF-00117', '2025-04-12', 'New', 'Approved', '2025-05-31', 'LC02', 'San Isidro Heights', 'ACQ-84803-25', '2025-03-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00142', 1, 'Identity', 'FILE-882181', '2025-04-12', 'Accepted', '2025-04-15', NULL),
('APP-2025-00142', 2, 'Registration', 'FILE-639623', '2025-04-14', 'Accepted', '2025-04-19', NULL),
('APP-2025-00142', 3, 'Acquisition', 'ACQ-84803-25', '2025-04-14', 'Accepted', '2025-04-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000143', 'APP-2025-00142', '2025-04-15', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00098', 'APP-2025-00142', '2025-06-05', '2025-06-05', '2026-06-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00143', 'AP-00133', 'GF-00101', '2025-04-12', 'New', 'Approved', '2025-05-02', 'LC08', 'San Rafael Norte', 'ACQ-16469-25', '2024-12-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00143', 1, 'Identity', 'FILE-806245', '2025-04-12', 'Accepted', '2025-04-19', NULL),
('APP-2025-00143', 2, 'Registration', 'DOC-598307', '2025-04-15', 'Accepted', '2025-04-17', NULL),
('APP-2025-00143', 3, 'Acquisition', 'ACQ-16469-25', '2025-04-12', 'Accepted', '2025-04-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000144', 'APP-2025-00143', '2025-04-12', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00099', 'APP-2025-00143', '2025-05-06', '2025-05-06', '2026-05-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00144', 'AP-00089', 'GF-00122', '2025-04-12', 'New', 'Approved', '2025-04-17', 'LC01', 'Luntian Central', 'ACQ-20831-25', '2025-03-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00144', 1, 'Identity', 'DOC-366573', '2025-04-12', 'Accepted', '2025-04-14', NULL),
('APP-2025-00144', 2, 'Registration', 'DOC-127344', '2025-04-14', 'Accepted', '2025-04-17', NULL),
('APP-2025-00144', 3, 'Acquisition', 'ACQ-20831-25', '2025-04-13', 'Accepted', '2025-04-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000145', 'APP-2025-00144', '2025-04-17', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00100', 'APP-2025-00144', '2025-04-20', '2025-04-20', '2026-04-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00145', 'AP-00181', 'GF-00071', '2025-04-12', 'New', 'Approved', '2025-04-26', 'LC07', 'Pulo Verde', 'ACQ-87859-25', '2025-01-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00145', 1, 'Identity', 'FILE-215290', '2025-04-12', 'Accepted', '2025-04-17', NULL),
('APP-2025-00145', 2, 'Registration', 'DOC-717188', '2025-04-15', 'Accepted', '2025-04-16', NULL),
('APP-2025-00145', 3, 'Acquisition', 'ACQ-87859-25', '2025-04-16', 'Accepted', '2025-04-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000146', 'APP-2025-00145', '2025-04-13', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00101', 'APP-2025-00145', '2025-04-29', '2025-04-29', '2026-04-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00146', 'AP-00053', 'GF-00055', '2025-04-13', 'New', 'Approved', '2025-04-21', 'LC07', 'Pulo Verde', 'ACQ-10231-25', '2025-02-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00146', 1, 'Identity', 'DOC-606199', '2025-04-13', 'Accepted', '2025-04-16', NULL),
('APP-2025-00146', 2, 'Registration', 'FILE-859741', '2025-04-13', 'Accepted', '2025-04-17', NULL),
('APP-2025-00146', 3, 'Acquisition', 'ACQ-10231-25', '2025-04-14', 'Accepted', '2025-04-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000147', 'APP-2025-00146', '2025-04-17', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00102', 'APP-2025-00146', '2025-04-26', '2025-04-26', '2026-04-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00147', 'AP-00094', 'GF-00084', '2025-04-13', 'New', 'Approved', '2025-04-21', 'LC03', 'Mabini East', 'ACQ-76176-25', '2025-03-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00147', 1, 'Identity', 'FILE-595673', '2025-04-13', 'Accepted', '2025-04-17', NULL),
('APP-2025-00147', 2, 'Registration', 'DOC-62129', '2025-04-16', 'Accepted', '2025-04-21', NULL),
('APP-2025-00147', 3, 'Acquisition', 'ACQ-76176-25', '2025-04-13', 'Accepted', '2025-04-20', NULL),
('APP-2025-00147', 4, 'Other', 'REF-558212', '2025-04-15', 'Accepted', '2025-04-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000148', 'APP-2025-00147', '2025-04-14', 1200, 'Online'),
('OR-2025-000149', 'APP-2025-00147', '2025-04-15', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00103', 'APP-2025-00147', '2025-04-24', '2025-04-24', '2026-04-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00148', 'AP-00148', 'GF-00150', '2025-04-15', 'New', 'Rejected', '2025-05-02', 'LC06', 'Maligaya', 'ACQ-25465-25', '2025-03-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00148', 1, 'Identity', 'FILE-963463', '2025-04-15', 'Pending', NULL, NULL),
('APP-2025-00148', 2, 'Registration', 'DOC-424733', '2025-04-19', 'NeedsCorrection', '2025-04-26', 'Please provide the missing page of the supporting document.'),
('APP-2025-00148', 3, 'Acquisition', 'ACQ-25465-25', '2025-04-19', 'Accepted', '2025-04-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000150', 'APP-2025-00148', '2025-04-24', 1200, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00149', 'AP-00016', 'GF-00012', '2025-04-17', 'New', 'Approved', '2025-04-24', 'LC06', 'Maligaya', 'ACQ-39267-25', '2025-03-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00149', 1, 'Identity', 'REF-11163', '2025-04-17', 'Accepted', '2025-04-19', NULL),
('APP-2025-00149', 2, 'Registration', 'FILE-525794', '2025-04-18', 'Accepted', '2025-04-19', NULL),
('APP-2025-00149', 3, 'Acquisition', 'ACQ-39267-25', '2025-04-22', 'Accepted', '2025-04-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000151', 'APP-2025-00149', '2025-04-18', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00104', 'APP-2025-00149', '2025-04-29', '2025-04-29', '2026-04-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00150', 'AP-00133', 'GF-00098', '2025-04-18', 'New', 'Rejected', '2025-04-26', 'LC08', 'San Rafael Norte', 'ACQ-38223-25', '2025-04-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00150', 1, 'Identity', 'FILE-673699', '2025-04-18', 'Accepted', '2025-04-25', NULL),
('APP-2025-00150', 2, 'Registration', 'FILE-278197', '2025-04-19', 'Accepted', '2025-04-21', NULL),
('APP-2025-00150', 3, 'Acquisition', 'ACQ-38223-25', '2025-04-18', 'Accepted', '2025-04-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000152', 'APP-2025-00150', '2025-04-26', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00151', 'AP-00107', 'GF-00054', '2025-04-19', 'New', 'Approved', '2025-05-13', 'LC06', 'Maligaya', 'ACQ-55937-25', '2024-12-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00151', 1, 'Identity', 'DOC-945379', '2025-04-19', 'Accepted', '2025-04-25', NULL),
('APP-2025-00151', 2, 'Registration', 'REF-896502', '2025-04-22', 'Accepted', '2025-04-23', NULL),
('APP-2025-00151', 3, 'Acquisition', 'ACQ-55937-25', '2025-04-23', 'Accepted', '2025-04-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000153', 'APP-2025-00151', '2025-04-26', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00105', 'APP-2025-00151', '2025-05-17', '2025-05-17', '2026-05-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00152', 'AP-00035', 'GF-00138', '2025-04-19', 'New', 'Approved', '2025-05-09', 'LC02', 'San Isidro Heights', 'ACQ-19759-25', '2025-03-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00152', 1, 'Identity', 'FILE-384993', '2025-04-19', 'Accepted', '2025-04-20', NULL),
('APP-2025-00152', 2, 'Registration', 'FILE-892836', '2025-04-23', 'Accepted', '2025-04-28', NULL),
('APP-2025-00152', 3, 'Acquisition', 'ACQ-19759-25', '2025-04-20', 'Accepted', '2025-04-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000154', 'APP-2025-00152', '2025-05-01', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00106', 'APP-2025-00152', '2025-05-12', '2025-05-12', '2026-05-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00153', 'AP-00116', 'GF-00115', '2025-04-21', 'New', 'Approved', '2025-05-07', 'LC04', 'Bagong Silangan', 'ACQ-41713-25', '2025-02-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00153', 1, 'Identity', 'FILE-716175', '2025-04-21', 'Accepted', '2025-04-24', NULL),
('APP-2025-00153', 2, 'Registration', 'REF-727077', '2025-04-23', 'Accepted', '2025-04-27', NULL),
('APP-2025-00153', 3, 'Acquisition', 'ACQ-41713-25', '2025-04-25', 'Accepted', '2025-05-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000155', 'APP-2025-00153', '2025-04-26', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00107', 'APP-2025-00153', '2025-05-11', '2025-05-11', '2026-05-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00154', 'AP-00094', 'GF-00091', '2025-04-21', 'New', 'Approved', '2025-05-13', 'LC03', 'Mabini East', 'ACQ-18445-25', '2024-12-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00154', 1, 'Identity', 'DOC-634040', '2025-04-21', 'Accepted', '2025-04-23', NULL),
('APP-2025-00154', 2, 'Registration', 'DOC-544873', '2025-04-22', 'Accepted', '2025-04-29', NULL),
('APP-2025-00154', 3, 'Acquisition', 'ACQ-18445-25', '2025-04-23', 'Accepted', '2025-04-30', NULL),
('APP-2025-00154', 4, 'Other', 'DOC-382957', '2025-04-25', 'Accepted', '2025-04-30', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00108', 'APP-2025-00154', '2025-05-17', '2025-05-17', '2026-05-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00155', 'AP-00173', 'GF-00040', '2025-04-21', 'New', 'Approved', '2025-04-24', 'LC01', 'Luntian Central', 'ACQ-26998-25', '2025-02-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00155', 1, 'Identity', 'DOC-64155', '2025-04-21', 'Accepted', '2025-04-24', NULL),
('APP-2025-00155', 2, 'Registration', 'FILE-248183', '2025-04-24', 'Accepted', '2025-04-24', NULL),
('APP-2025-00155', 3, 'Acquisition', 'ACQ-26998-25', '2025-04-24', 'Accepted', '2025-04-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000156', 'APP-2025-00155', '2025-04-24', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00109', 'APP-2025-00155', '2025-04-27', '2025-04-27', '2026-04-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00156', 'AP-00097', 'GF-00036', '2025-04-22', 'New', 'Approved', '2025-05-12', 'LC01', 'Luntian Central', 'ACQ-65103-25', '2024-12-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00156', 1, 'Identity', 'REF-258359', '2025-04-22', 'Accepted', '2025-04-25', NULL),
('APP-2025-00156', 2, 'Registration', 'DOC-618809', '2025-04-25', 'Accepted', '2025-04-27', NULL),
('APP-2025-00156', 3, 'Acquisition', 'ACQ-65103-25', '2025-04-27', 'Accepted', '2025-04-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000157', 'APP-2025-00156', '2025-04-29', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00110', 'APP-2025-00156', '2025-05-12', '2025-05-12', '2026-05-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00157', 'AP-00017', 'GF-00162', '2025-04-27', 'New', 'Approved', '2025-05-01', 'LC03', 'Mabini East', 'ACQ-81966-25', '2025-02-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00157', 1, 'Identity', 'FILE-418043', '2025-04-27', 'Accepted', '2025-05-01', NULL),
('APP-2025-00157', 2, 'Registration', 'DOC-218867', '2025-04-27', 'Accepted', '2025-04-30', NULL),
('APP-2025-00157', 3, 'Acquisition', 'ACQ-81966-25', '2025-05-01', 'Accepted', '2025-05-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000158', 'APP-2025-00157', '2025-05-01', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00111', 'APP-2025-00157', '2025-05-02', '2025-05-02', '2026-05-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00158', 'AP-00097', 'GF-00160', '2025-04-28', 'New', 'Approved', '2025-05-10', 'LC05', 'Santa Elena', 'ACQ-32193-25', '2025-02-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00158', 1, 'Identity', 'FILE-995316', '2025-04-28', 'Accepted', '2025-05-02', NULL),
('APP-2025-00158', 2, 'Registration', 'FILE-783859', '2025-04-29', 'Accepted', '2025-05-02', NULL),
('APP-2025-00158', 3, 'Acquisition', 'ACQ-32193-25', '2025-05-03', 'Accepted', '2025-05-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000159', 'APP-2025-00158', '2025-05-06', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00112', 'APP-2025-00158', '2025-05-10', '2025-05-10', '2026-05-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00159', 'AP-00074', 'GF-00116', '2025-05-02', 'New', 'Approved', '2025-05-14', 'LC02', 'San Isidro Heights', 'ACQ-63741-25', '2025-02-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00159', 1, 'Identity', 'FILE-66166', '2025-05-02', 'Accepted', '2025-05-04', NULL),
('APP-2025-00159', 2, 'Registration', 'FILE-193067', '2025-05-07', 'Accepted', '2025-05-08', NULL),
('APP-2025-00159', 3, 'Acquisition', 'ACQ-63741-25', '2025-05-02', 'Accepted', '2025-05-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000160', 'APP-2025-00159', '2025-05-07', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00113', 'APP-2025-00159', '2025-05-19', '2025-05-19', '2026-05-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00160', 'AP-00087', 'GF-00074', '2025-05-03', 'New', 'Withdrawn', NULL, 'LC03', 'Mabini East', 'ACQ-14534-25', '2025-04-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00160', 1, 'Identity', 'REF-439976', '2025-05-03', 'Accepted', '2025-05-05', NULL),
('APP-2025-00160', 2, 'Registration', 'REF-218774', '2025-05-05', 'Accepted', '2025-05-08', NULL),
('APP-2025-00160', 3, 'Acquisition', 'ACQ-14534-25', '2025-05-06', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00161', 'AP-00050', 'GF-00145', '2025-05-03', 'New', 'Approved', '2025-05-28', 'LC03', 'Mabini East', 'ACQ-38709-25', '2025-01-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00161', 1, 'Identity', 'REF-735301', '2025-05-03', 'Accepted', '2025-05-06', NULL),
('APP-2025-00161', 2, 'Registration', 'DOC-68076', '2025-05-04', 'Accepted', '2025-05-10', NULL),
('APP-2025-00161', 3, 'Acquisition', 'ACQ-38709-25', '2025-05-08', 'Accepted', '2025-05-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000161', 'APP-2025-00161', '2025-05-12', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00114', 'APP-2025-00161', '2025-05-31', '2025-05-31', '2026-05-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00162', 'AP-00117', 'GF-00021', '2025-05-03', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-19388-25', '2025-02-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00162', 1, 'Identity', 'REF-284131', '2025-05-03', 'Pending', NULL, NULL),
('APP-2025-00162', 2, 'Registration', 'DOC-649428', '2025-05-05', 'Pending', NULL, NULL),
('APP-2025-00162', 3, 'Acquisition', 'ACQ-19388-25', '2025-05-08', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000162', 'APP-2025-00162', '2025-05-06', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00163', 'AP-00041', 'GF-00126', '2025-05-04', 'New', 'Approved', '2025-05-11', 'LC05', 'Santa Elena', 'ACQ-13374-25', '2025-01-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00163', 1, 'Identity', 'FILE-571592', '2025-05-04', 'Accepted', '2025-05-06', NULL),
('APP-2025-00163', 2, 'Registration', 'FILE-233768', '2025-05-07', 'Accepted', '2025-05-11', NULL),
('APP-2025-00163', 3, 'Acquisition', 'ACQ-13374-25', '2025-05-09', 'Accepted', '2025-05-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000163', 'APP-2025-00163', '2025-05-11', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00115', 'APP-2025-00163', '2025-05-13', '2025-05-13', '2026-05-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00164', 'AP-00159', 'GF-00128', '2025-05-05', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-93611-25', '2025-04-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00164', 1, 'Identity', 'FILE-807587', '2025-05-05', 'Accepted', '2025-05-06', NULL),
('APP-2025-00164', 2, 'Registration', 'FILE-180700', '2025-05-07', 'Pending', NULL, NULL),
('APP-2025-00164', 3, 'Acquisition', 'ACQ-93611-25', '2025-05-09', 'Accepted', '2025-05-10', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00165', 'AP-00159', 'GF-00115', '2025-05-07', 'New', 'Approved', '2025-05-12', 'LC04', 'Bagong Silangan', 'ACQ-66127-25', '2025-01-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00165', 1, 'Identity', 'REF-379456', '2025-05-07', 'Accepted', '2025-05-08', NULL),
('APP-2025-00165', 2, 'Registration', 'REF-919669', '2025-05-09', 'Accepted', '2025-05-12', NULL),
('APP-2025-00165', 3, 'Acquisition', 'ACQ-66127-25', '2025-05-09', 'Accepted', '2025-05-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000164', 'APP-2025-00165', '2025-05-08', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00116', 'APP-2025-00165', '2025-05-16', '2025-05-16', '2026-05-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00166', 'AP-00106', 'GF-00139', '2025-05-10', 'New', 'Approved', '2025-05-22', 'LC02', 'San Isidro Heights', 'ACQ-69593-25', '2025-02-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00166', 1, 'Identity', 'DOC-87822', '2025-05-10', 'Accepted', '2025-05-15', NULL),
('APP-2025-00166', 2, 'Registration', 'REF-140049', '2025-05-13', 'Accepted', '2025-05-17', NULL),
('APP-2025-00166', 3, 'Acquisition', 'ACQ-69593-25', '2025-05-14', 'Accepted', '2025-05-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000165', 'APP-2025-00166', '2025-05-17', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00117', 'APP-2025-00166', '2025-05-24', '2025-05-24', '2026-05-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00167', 'AP-00129', 'GF-00069', '2025-05-11', 'New', 'Approved', '2025-06-04', 'LC01', 'Luntian Central', 'ACQ-81412-25', '2025-03-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00167', 1, 'Identity', 'DOC-552943', '2025-05-11', 'Accepted', '2025-05-12', NULL),
('APP-2025-00167', 2, 'Registration', 'FILE-345410', '2025-05-13', 'Accepted', '2025-05-18', NULL),
('APP-2025-00167', 3, 'Acquisition', 'ACQ-81412-25', '2025-05-11', 'Accepted', '2025-05-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000166', 'APP-2025-00167', '2025-05-14', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00118', 'APP-2025-00167', '2025-06-05', '2025-06-05', '2026-06-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00168', 'AP-00039', 'GF-00078', '2025-05-13', 'New', 'Approved', '2025-06-14', 'LC01', 'Luntian Central', 'ACQ-65249-25', '2025-01-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00168', 1, 'Identity', 'FILE-976398', '2025-05-13', 'Accepted', '2025-05-14', NULL),
('APP-2025-00168', 2, 'Registration', 'REF-981665', '2025-05-13', 'Accepted', '2025-05-20', NULL),
('APP-2025-00168', 3, 'Acquisition', 'ACQ-65249-25', '2025-05-13', 'Accepted', '2025-05-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000167', 'APP-2025-00168', '2025-05-23', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00119', 'APP-2025-00168', '2025-06-15', '2025-06-15', '2026-06-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00169', 'AP-00029', 'GF-00100', '2025-05-13', 'New', 'Approved', '2025-06-06', 'LC02', 'San Isidro Heights', 'ACQ-83349-25', '2025-04-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00169', 1, 'Identity', 'DOC-729044', '2025-05-13', 'Accepted', '2025-05-16', NULL),
('APP-2025-00169', 2, 'Registration', 'FILE-122853', '2025-05-14', 'Accepted', '2025-05-19', NULL),
('APP-2025-00169', 3, 'Acquisition', 'ACQ-83349-25', '2025-05-14', 'Accepted', '2025-05-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000168', 'APP-2025-00169', '2025-05-19', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00120', 'APP-2025-00169', '2025-06-08', '2025-06-08', '2026-06-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00170', 'AP-00136', 'GF-00028', '2025-05-14', 'New', 'Approved', '2025-06-04', 'LC02', 'San Isidro Heights', 'ACQ-83820-25', '2025-02-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00170', 1, 'Identity', 'DOC-178748', '2025-05-14', 'Accepted', '2025-05-18', NULL),
('APP-2025-00170', 2, 'Registration', 'REF-597351', '2025-05-14', 'Accepted', '2025-05-18', NULL),
('APP-2025-00170', 3, 'Acquisition', 'ACQ-83820-25', '2025-05-16', 'Accepted', '2025-05-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000169', 'APP-2025-00170', '2025-05-26', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00121', 'APP-2025-00170', '2025-06-04', '2025-06-04', '2026-06-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00171', 'AP-00029', 'GF-00108', '2025-05-14', 'New', 'Approved', '2025-05-26', 'LC02', 'San Isidro Heights', 'ACQ-78412-25', '2025-04-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00171', 1, 'Identity', 'REF-271823', '2025-05-14', 'Accepted', '2025-05-17', NULL),
('APP-2025-00171', 2, 'Registration', 'DOC-925788', '2025-05-18', 'Accepted', '2025-05-22', NULL),
('APP-2025-00171', 3, 'Acquisition', 'ACQ-78412-25', '2025-05-18', 'Accepted', '2025-05-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000170', 'APP-2025-00171', '2025-05-16', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00122', 'APP-2025-00171', '2025-05-29', '2025-05-29', '2026-05-28', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00172', 'AP-00152', 'GF-00089', '2025-05-15', 'New', 'Approved', '2025-05-25', 'LC07', 'Pulo Verde', 'ACQ-15415-25', '2025-05-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00172', 1, 'Identity', 'REF-277765', '2025-05-15', 'Accepted', '2025-05-19', NULL),
('APP-2025-00172', 2, 'Registration', 'FILE-226027', '2025-05-20', 'Accepted', '2025-05-25', NULL),
('APP-2025-00172', 3, 'Acquisition', 'ACQ-15415-25', '2025-05-16', 'Accepted', '2025-05-20', NULL),
('APP-2025-00172', 4, 'Other', 'FILE-723640', '2025-05-20', 'Accepted', '2025-05-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000171', 'APP-2025-00172', '2025-05-18', 1200, 'Online'),
('OR-2025-000172', 'APP-2025-00172', '2025-05-22', 200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00123', 'APP-2025-00172', '2025-05-27', '2025-05-27', '2026-05-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00173', 'AP-00066', 'GF-00152', '2025-05-15', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-35525-25', '2025-03-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00173', 1, 'Identity', 'FILE-49839', '2025-05-15', 'Pending', NULL, NULL),
('APP-2025-00173', 2, 'Registration', 'DOC-187701', '2025-05-15', 'Accepted', '2025-05-17', NULL),
('APP-2025-00173', 3, 'Acquisition', 'ACQ-35525-25', '2025-05-15', 'Accepted', '2025-05-21', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00174', 'AP-00044', 'GF-00020', '2025-05-16', 'New', 'Approved', '2025-05-22', 'LC01', 'Luntian Central', 'ACQ-23680-25', '2025-04-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00174', 1, 'Identity', 'REF-511591', '2025-05-16', 'Accepted', '2025-05-22', NULL),
('APP-2025-00174', 2, 'Registration', 'DOC-426053', '2025-05-17', 'Accepted', '2025-05-22', NULL),
('APP-2025-00174', 3, 'Acquisition', 'ACQ-23680-25', '2025-05-21', 'Accepted', '2025-05-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000173', 'APP-2025-00174', '2025-05-19', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00124', 'APP-2025-00174', '2025-05-24', '2025-05-24', '2026-05-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00175', 'AP-00162', 'GF-00082', '2025-05-17', 'New', 'Approved', '2025-06-05', 'LC01', 'Luntian Central', 'ACQ-44257-25', '2025-03-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00175', 1, 'Identity', 'REF-552532', '2025-05-17', 'Accepted', '2025-05-20', NULL),
('APP-2025-00175', 2, 'Registration', 'DOC-580674', '2025-05-18', 'Accepted', '2025-05-20', NULL),
('APP-2025-00175', 3, 'Acquisition', 'ACQ-44257-25', '2025-05-21', 'Accepted', '2025-05-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000174', 'APP-2025-00175', '2025-05-19', 1200, 'Online'),
('OR-2025-000175', 'APP-2025-00175', '2025-05-26', 100, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00176', 'AP-00005', 'GF-00160', '2025-05-19', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-87040-25', '2025-05-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00176', 1, 'Identity', 'FILE-311498', '2025-05-19', 'Accepted', '2025-05-26', NULL),
('APP-2025-00176', 2, 'Registration', 'DOC-832901', '2025-05-19', 'Pending', NULL, NULL),
('APP-2025-00176', 3, 'Acquisition', 'ACQ-87040-25', '2025-05-24', 'Pending', NULL, NULL),
('APP-2025-00176', 4, 'Other', 'REF-838642', '2025-05-21', 'Accepted', '2025-05-28', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00177', 'AP-00009', 'GF-00152', '2025-05-19', 'New', 'Approved', '2025-06-01', 'LC02', 'San Isidro Heights', 'ACQ-22397-25', '2025-04-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00177', 1, 'Identity', 'FILE-541956', '2025-05-19', 'Accepted', '2025-05-26', NULL),
('APP-2025-00177', 2, 'Registration', 'REF-438314', '2025-05-21', 'Accepted', '2025-05-27', NULL),
('APP-2025-00177', 3, 'Acquisition', 'ACQ-22397-25', '2025-05-23', 'Accepted', '2025-05-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000176', 'APP-2025-00177', '2025-05-19', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00125', 'APP-2025-00177', '2025-06-04', '2025-06-04', '2026-06-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00178', 'AP-00172', 'GF-00122', '2025-05-19', 'New', 'Approved', '2025-05-31', 'LC06', 'Maligaya', 'ACQ-85881-25', '2025-04-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00178', 1, 'Identity', 'FILE-753194', '2025-05-19', 'Accepted', '2025-05-20', NULL),
('APP-2025-00178', 2, 'Registration', 'FILE-548422', '2025-05-19', 'Accepted', '2025-05-24', NULL),
('APP-2025-00178', 3, 'Acquisition', 'ACQ-85881-25', '2025-05-24', 'Accepted', '2025-05-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000177', 'APP-2025-00178', '2025-05-25', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00126', 'APP-2025-00178', '2025-06-01', '2025-06-01', '2026-05-31', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00179', 'AP-00011', 'GF-00090', '2025-05-19', 'New', 'Withdrawn', NULL, 'LC03', 'Mabini East', 'ACQ-73391-25', '2025-05-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00179', 1, 'Identity', 'REF-851652', '2025-05-19', 'Accepted', '2025-05-24', NULL),
('APP-2025-00179', 2, 'Registration', 'DOC-220962', '2025-05-23', 'NeedsCorrection', '2025-05-24', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00179', 3, 'Acquisition', 'ACQ-73391-25', '2025-05-19', 'Accepted', '2025-05-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000178', 'APP-2025-00179', '2025-05-30', 1200, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00180', 'AP-00057', 'GF-00011', '2025-05-20', 'New', 'Approved', '2025-07-09', 'LC03', 'Mabini East', 'ACQ-83350-25', '2025-01-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00180', 1, 'Identity', 'REF-909043', '2025-05-20', 'Accepted', '2025-05-25', NULL),
('APP-2025-00180', 2, 'Registration', 'FILE-16576', '2025-05-20', 'Accepted', '2025-05-22', NULL),
('APP-2025-00180', 3, 'Acquisition', 'ACQ-83350-25', '2025-05-24', 'Accepted', '2025-05-29', NULL),
('APP-2025-00180', 4, 'Other', 'DOC-649920', '2025-05-20', 'Accepted', '2025-05-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000179', 'APP-2025-00180', '2025-05-31', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00127', 'APP-2025-00180', '2025-07-13', '2025-07-13', '2026-07-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00181', 'AP-00123', 'GF-00125', '2025-05-21', 'New', 'Rejected', '2025-06-02', 'LC01', 'Luntian Central', 'ACQ-69367-25', '2025-04-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00181', 1, 'Identity', 'REF-884636', '2025-05-21', 'Accepted', '2025-05-28', NULL),
('APP-2025-00181', 2, 'Registration', 'REF-322560', '2025-05-24', 'Accepted', '2025-05-30', NULL),
('APP-2025-00181', 3, 'Acquisition', 'ACQ-69367-25', '2025-05-24', 'NeedsCorrection', '2025-05-25', 'Please provide the missing page of the supporting document.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00182', 'AP-00103', 'GF-00004', '2025-05-23', 'New', 'Approved', '2025-06-11', 'LC07', 'Pulo Verde', 'ACQ-66814-25', '2025-04-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00182', 1, 'Identity', 'DOC-143179', '2025-05-23', 'Accepted', '2025-05-30', NULL),
('APP-2025-00182', 2, 'Registration', 'DOC-404788', '2025-05-24', 'Accepted', '2025-05-30', NULL),
('APP-2025-00182', 3, 'Acquisition', 'ACQ-66814-25', '2025-05-24', 'Accepted', '2025-05-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000180', 'APP-2025-00182', '2025-05-23', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00128', 'APP-2025-00182', '2025-06-14', '2025-06-14', '2026-06-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00183', 'AP-00082', 'GF-00156', '2025-05-24', 'New', 'Approved', '2025-07-21', 'LC07', 'Pulo Verde', 'ACQ-33673-25', '2025-05-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00183', 1, 'Identity', 'REF-596955', '2025-05-24', 'Accepted', '2025-05-30', NULL),
('APP-2025-00183', 2, 'Registration', 'REF-738239', '2025-05-28', 'Accepted', '2025-06-01', NULL),
('APP-2025-00183', 3, 'Acquisition', 'ACQ-33673-25', '2025-05-25', 'Accepted', '2025-05-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000181', 'APP-2025-00183', '2025-06-05', 750, 'BankTransfer'),
('OR-2025-000182', 'APP-2025-00183', '2025-05-30', 100, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00129', 'APP-2025-00183', '2025-07-25', '2025-07-25', '2026-07-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00184', 'AP-00075', 'GF-00024', '2025-05-26', 'New', 'Approved', '2025-06-07', 'LC01', 'Luntian Central', 'ACQ-26477-25', '2025-04-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00184', 1, 'Identity', 'REF-17912', '2025-05-26', 'Accepted', '2025-06-02', NULL),
('APP-2025-00184', 2, 'Registration', 'DOC-778959', '2025-05-31', 'Accepted', '2025-06-05', NULL),
('APP-2025-00184', 3, 'Acquisition', 'ACQ-26477-25', '2025-05-29', 'Accepted', '2025-06-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000183', 'APP-2025-00184', '2025-06-01', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00130', 'APP-2025-00184', '2025-06-12', '2025-06-12', '2026-06-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00185', 'AP-00125', 'GF-00148', '2025-05-26', 'New', 'Submitted', NULL, 'LC04', 'Bagong Silangan', 'ACQ-33860-25', '2025-03-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00185', 1, 'Identity', 'DOC-656623', '2025-05-26', 'Pending', NULL, NULL),
('APP-2025-00185', 2, 'Registration', 'FILE-337001', '2025-05-30', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000184', 'APP-2025-00185', '2025-06-07', 600, 'Online'),
('OR-2025-000185', 'APP-2025-00185', '2025-06-02', 200, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00186', 'AP-00028', 'GF-00118', '2025-05-29', 'New', 'Approved', '2025-06-02', 'LC01', 'Luntian Central', 'ACQ-20495-25', '2025-03-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00186', 1, 'Identity', 'DOC-691442', '2025-05-29', 'Accepted', '2025-06-02', NULL),
('APP-2025-00186', 2, 'Registration', 'FILE-964725', '2025-05-29', 'Accepted', '2025-06-02', NULL),
('APP-2025-00186', 3, 'Acquisition', 'ACQ-20495-25', '2025-06-01', 'Accepted', '2025-06-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000186', 'APP-2025-00186', '2025-06-02', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00131', 'APP-2025-00186', '2025-06-05', '2025-06-05', '2026-06-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00187', 'AP-00066', 'GF-00114', '2025-05-30', 'New', 'Rejected', '2025-06-08', 'LC04', 'Bagong Silangan', 'ACQ-89375-25', '2025-05-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00187', 1, 'Identity', 'FILE-552612', '2025-05-30', 'Accepted', '2025-06-01', NULL),
('APP-2025-00187', 2, 'Registration', 'REF-460876', '2025-05-31', 'Accepted', '2025-06-03', NULL),
('APP-2025-00187', 3, 'Acquisition', 'ACQ-89375-25', '2025-06-03', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000187', 'APP-2025-00187', '2025-06-04', 450, 'BankTransfer'),
('OR-2025-000188', 'APP-2025-00187', '2025-06-06', 250, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00188', 'AP-00172', 'GF-00152', '2025-05-30', 'New', 'Approved', '2025-06-04', 'LC06', 'Maligaya', 'ACQ-96621-25', '2025-05-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00188', 1, 'Identity', 'REF-986215', '2025-05-30', 'Accepted', '2025-05-31', NULL),
('APP-2025-00188', 2, 'Registration', 'FILE-165637', '2025-05-30', 'Accepted', '2025-06-04', NULL),
('APP-2025-00188', 3, 'Acquisition', 'ACQ-96621-25', '2025-06-04', 'Accepted', '2025-06-04', NULL),
('APP-2025-00188', 4, 'Other', 'REF-162566', '2025-05-30', 'Accepted', '2025-06-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000189', 'APP-2025-00188', '2025-06-04', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00132', 'APP-2025-00188', '2025-06-06', '2025-06-06', '2026-06-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00189', 'AP-00085', 'GF-00042', '2025-06-01', 'New', 'Approved', '2025-06-11', 'LC03', 'Mabini East', 'ACQ-97861-25', '2025-02-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00189', 1, 'Identity', 'REF-49041', '2025-06-01', 'Accepted', '2025-06-05', NULL),
('APP-2025-00189', 2, 'Registration', 'DOC-441225', '2025-06-06', 'Accepted', '2025-06-11', NULL),
('APP-2025-00189', 3, 'Acquisition', 'ACQ-97861-25', '2025-06-06', 'Accepted', '2025-06-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000190', 'APP-2025-00189', '2025-06-11', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00133', 'APP-2025-00189', '2025-06-11', '2025-06-11', '2026-06-10', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00190', 'AP-00052', 'GF-00146', '2025-06-02', 'New', 'Approved', '2025-06-10', 'LC01', 'Luntian Central', 'ACQ-48792-25', '2025-02-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00190', 1, 'Identity', 'DOC-847742', '2025-06-02', 'Accepted', '2025-06-07', NULL),
('APP-2025-00190', 2, 'Registration', 'REF-354888', '2025-06-02', 'Accepted', '2025-06-05', NULL),
('APP-2025-00190', 3, 'Acquisition', 'ACQ-48792-25', '2025-06-06', 'Accepted', '2025-06-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000191', 'APP-2025-00190', '2025-06-07', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00134', 'APP-2025-00190', '2025-06-15', '2025-06-15', '2026-06-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00191', 'AP-00041', 'GF-00087', '2025-06-02', 'New', 'Rejected', '2025-06-11', 'LC05', 'Santa Elena', 'ACQ-19467-25', '2025-02-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00191', 1, 'Identity', 'REF-842765', '2025-06-02', 'NeedsCorrection', '2025-06-04', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00191', 2, 'Registration', 'FILE-644128', '2025-06-04', 'Pending', NULL, NULL),
('APP-2025-00191', 3, 'Acquisition', 'ACQ-19467-25', '2025-06-02', 'NeedsCorrection', '2025-06-08', 'A clearer copy of the reference portion is requested.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000192', 'APP-2025-00191', '2025-06-11', 750, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00192', 'AP-00135', 'GF-00036', '2025-06-02', 'New', 'Approved', '2025-07-11', 'LC01', 'Luntian Central', 'ACQ-70234-25', '2025-02-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00192', 1, 'Identity', 'REF-947132', '2025-06-02', 'Accepted', '2025-06-07', NULL),
('APP-2025-00192', 2, 'Registration', 'REF-976050', '2025-06-02', 'Accepted', '2025-06-09', NULL),
('APP-2025-00192', 3, 'Acquisition', 'ACQ-70234-25', '2025-06-07', 'Accepted', '2025-06-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000193', 'APP-2025-00192', '2025-06-07', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00135', 'APP-2025-00192', '2025-07-16', '2025-07-16', '2026-07-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00193', 'AP-00154', 'GF-00092', '2025-06-02', 'Replacement', 'Approved', '2025-06-29', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2025-05-09', 'IR-2025-8012');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00193', 1, 'Identity', 'DOC-599141', '2025-06-02', 'Accepted', '2025-06-08', NULL),
('APP-2025-00193', 2, 'Registration', 'REF-611011', '2025-06-05', 'Accepted', '2025-06-09', NULL),
('APP-2025-00193', 3, 'Incident', 'IR-2025-8012', '2025-06-07', 'Accepted', '2025-06-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000194', 'APP-2025-00193', '2025-06-10', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00136', 'APP-2025-00193', '2025-06-30', '2025-06-30', '2026-06-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00194', 'AP-00057', 'GF-00019', '2025-06-04', 'New', 'Approved', '2025-06-10', 'LC03', 'Mabini East', 'ACQ-57873-25', '2025-06-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00194', 1, 'Identity', 'FILE-947584', '2025-06-04', 'Accepted', '2025-06-10', NULL),
('APP-2025-00194', 2, 'Registration', 'DOC-454104', '2025-06-04', 'Accepted', '2025-06-10', NULL),
('APP-2025-00194', 3, 'Acquisition', 'ACQ-57873-25', '2025-06-08', 'Accepted', '2025-06-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000195', 'APP-2025-00194', '2025-06-10', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00137', 'APP-2025-00194', '2025-06-13', '2025-06-13', '2026-06-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00195', 'AP-00124', 'GF-00008', '2025-06-05', 'New', 'Approved', '2025-06-10', 'LC06', 'Maligaya', 'ACQ-73767-25', '2025-03-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00195', 1, 'Identity', 'FILE-870515', '2025-06-05', 'Accepted', '2025-06-10', NULL),
('APP-2025-00195', 2, 'Registration', 'FILE-633451', '2025-06-08', 'Accepted', '2025-06-10', NULL),
('APP-2025-00195', 3, 'Acquisition', 'ACQ-73767-25', '2025-06-09', 'Accepted', '2025-06-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000196', 'APP-2025-00195', '2025-06-07', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00138', 'APP-2025-00195', '2025-06-14', '2025-06-14', '2026-06-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00196', 'AP-00048', 'GF-00053', '2025-06-05', 'New', 'Approved', '2025-06-20', 'LC03', 'Mabini East', 'ACQ-32305-25', '2025-04-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00196', 1, 'Identity', 'FILE-64080', '2025-06-05', 'Accepted', '2025-06-08', NULL),
('APP-2025-00196', 2, 'Registration', 'DOC-12452', '2025-06-05', 'Accepted', '2025-06-12', NULL),
('APP-2025-00196', 3, 'Acquisition', 'ACQ-32305-25', '2025-06-08', 'Accepted', '2025-06-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000197', 'APP-2025-00196', '2025-06-09', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00197', 'AP-00099', 'GF-00165', '2025-06-07', 'New', 'Approved', '2025-06-13', 'LC03', 'Mabini East', 'ACQ-58987-25', '2025-06-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00197', 1, 'Identity', 'FILE-201633', '2025-06-07', 'Accepted', '2025-06-12', NULL),
('APP-2025-00197', 2, 'Registration', 'FILE-674329', '2025-06-11', 'Accepted', '2025-06-12', NULL),
('APP-2025-00197', 3, 'Acquisition', 'ACQ-58987-25', '2025-06-12', 'Accepted', '2025-06-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000198', 'APP-2025-00197', '2025-06-13', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00139', 'APP-2025-00197', '2025-06-18', '2025-06-18', '2026-06-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00198', 'AP-00050', 'GF-00011', '2025-06-10', 'New', 'Approved', '2025-06-14', 'LC03', 'Mabini East', 'ACQ-76496-25', '2025-03-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00198', 1, 'Identity', 'DOC-294305', '2025-06-10', 'Accepted', '2025-06-12', NULL),
('APP-2025-00198', 2, 'Registration', 'FILE-970937', '2025-06-13', 'Accepted', '2025-06-14', NULL),
('APP-2025-00198', 3, 'Acquisition', 'ACQ-76496-25', '2025-06-12', 'Accepted', '2025-06-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000199', 'APP-2025-00198', '2025-06-14', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00140', 'APP-2025-00198', '2025-06-19', '2025-06-19', '2026-06-18', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00199', 'AP-00118', 'GF-00009', '2025-06-10', 'New', 'Approved', '2025-07-05', 'LC05', 'Santa Elena', 'ACQ-54031-25', '2025-03-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00199', 1, 'Identity', 'REF-539675', '2025-06-10', 'Accepted', '2025-06-15', NULL),
('APP-2025-00199', 2, 'Registration', 'DOC-268856', '2025-06-12', 'Accepted', '2025-06-17', NULL),
('APP-2025-00199', 3, 'Acquisition', 'ACQ-54031-25', '2025-06-12', 'Accepted', '2025-06-14', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00141', 'APP-2025-00199', '2025-07-10', '2025-07-10', '2026-07-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00200', 'AP-00132', 'GF-00047', '2025-06-11', 'New', 'Approved', '2025-06-22', 'LC02', 'San Isidro Heights', 'ACQ-18772-25', '2025-06-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00200', 1, 'Identity', 'DOC-245676', '2025-06-11', 'Accepted', '2025-06-15', NULL),
('APP-2025-00200', 2, 'Registration', 'DOC-313295', '2025-06-13', 'Accepted', '2025-06-15', NULL),
('APP-2025-00200', 3, 'Acquisition', 'ACQ-18772-25', '2025-06-12', 'Accepted', '2025-06-13', NULL),
('APP-2025-00200', 4, 'Other', 'FILE-384611', '2025-06-12', 'Accepted', '2025-06-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000200', 'APP-2025-00200', '2025-06-22', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00142', 'APP-2025-00200', '2025-06-24', '2025-06-24', '2026-06-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00201', 'AP-00025', 'GF-00032', '2025-06-14', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-98002-25', '2025-06-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00201', 1, 'Identity', 'FILE-444491', '2025-06-14', 'Pending', NULL, NULL),
('APP-2025-00201', 2, 'Registration', 'DOC-106588', '2025-06-19', 'Accepted', '2025-06-20', NULL),
('APP-2025-00201', 3, 'Acquisition', 'ACQ-98002-25', '2025-06-14', 'NeedsCorrection', '2025-06-16', 'A clearer copy of the reference portion is requested.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000201', 'APP-2025-00201', '2025-06-25', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00202', 'AP-00051', 'GF-00109', '2025-06-15', 'New', 'Submitted', NULL, 'LC02', 'San Isidro Heights', 'ACQ-17937-25', '2025-03-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00202', 1, 'Identity', 'REF-908128', '2025-06-15', 'Pending', NULL, NULL),
('APP-2025-00202', 2, 'Other', 'DOC-226302', '2025-06-17', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00203', 'AP-00091', 'GF-00094', '2025-06-16', 'New', 'Approved', '2025-07-26', 'LC02', 'San Isidro Heights', 'ACQ-86326-25', '2025-03-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00203', 1, 'Identity', 'REF-118362', '2025-06-16', 'Accepted', '2025-06-20', NULL),
('APP-2025-00203', 2, 'Registration', 'REF-517716', '2025-06-20', 'Accepted', '2025-06-21', NULL),
('APP-2025-00203', 3, 'Acquisition', 'ACQ-86326-25', '2025-06-21', 'Accepted', '2025-06-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000202', 'APP-2025-00203', '2025-06-21', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00143', 'APP-2025-00203', '2025-07-31', '2025-07-31', '2026-07-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00204', 'AP-00154', 'GF-00092', '2025-06-16', 'Replacement', 'Approved', '2025-08-14', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2025-05-30', 'IR-2025-1934');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00204', 1, 'Identity', 'DOC-697380', '2025-06-16', 'Accepted', '2025-06-19', NULL),
('APP-2025-00204', 2, 'Registration', 'DOC-577701', '2025-06-19', 'Accepted', '2025-06-20', NULL),
('APP-2025-00204', 3, 'Incident', 'IR-2025-1934', '2025-06-16', 'Accepted', '2025-06-21', NULL),
('APP-2025-00204', 4, 'Other', 'FILE-184122', '2025-06-19', 'Accepted', '2025-06-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000203', 'APP-2025-00204', '2025-06-22', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00144', 'APP-2025-00204', '2025-08-19', '2025-08-19', '2026-08-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00205', 'AP-00091', 'GF-00029', '2025-06-18', 'New', 'Approved', '2025-06-27', 'LC02', 'San Isidro Heights', 'ACQ-66437-25', '2025-06-05', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00205', 1, 'Identity', 'DOC-988110', '2025-06-18', 'Accepted', '2025-06-19', NULL),
('APP-2025-00205', 2, 'Registration', 'FILE-638370', '2025-06-22', 'Accepted', '2025-06-23', NULL),
('APP-2025-00205', 3, 'Acquisition', 'ACQ-66437-25', '2025-06-21', 'Accepted', '2025-06-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000204', 'APP-2025-00205', '2025-06-25', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00206', 'AP-00139', 'GF-00149', '2025-06-19', 'New', 'Approved', '2025-06-27', 'LC04', 'Bagong Silangan', 'ACQ-78507-25', '2025-03-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00206', 1, 'Identity', 'DOC-167562', '2025-06-19', 'Accepted', '2025-06-24', NULL),
('APP-2025-00206', 2, 'Registration', 'FILE-510914', '2025-06-22', 'Accepted', '2025-06-24', NULL),
('APP-2025-00206', 3, 'Acquisition', 'ACQ-78507-25', '2025-06-22', 'Accepted', '2025-06-23', NULL),
('APP-2025-00206', 4, 'Other', 'DOC-82053', '2025-06-22', 'Accepted', '2025-06-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000205', 'APP-2025-00206', '2025-06-26', 900, 'Online'),
('OR-2025-000206', 'APP-2025-00206', '2025-06-26', 200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00145', 'APP-2025-00206', '2025-06-29', '2025-06-29', '2026-06-28', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00207', 'AP-00180', 'GF-00068', '2025-06-20', 'New', 'Approved', '2025-07-15', 'LC07', 'Pulo Verde', 'ACQ-30762-25', '2025-05-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00207', 1, 'Identity', 'DOC-599517', '2025-06-20', 'Accepted', '2025-06-23', NULL),
('APP-2025-00207', 2, 'Registration', 'DOC-959881', '2025-06-23', 'Accepted', '2025-06-27', NULL),
('APP-2025-00207', 3, 'Acquisition', 'ACQ-30762-25', '2025-06-22', 'Accepted', '2025-06-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000207', 'APP-2025-00207', '2025-06-22', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00146', 'APP-2025-00207', '2025-07-19', '2025-07-19', '2026-07-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00208', 'AP-00098', 'GF-00050', '2025-06-22', 'New', 'Rejected', '2025-07-14', 'LC01', 'Luntian Central', 'ACQ-12483-25', '2025-06-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00208', 1, 'Identity', 'REF-961198', '2025-06-22', 'Accepted', '2025-06-24', NULL),
('APP-2025-00208', 2, 'Registration', 'DOC-917194', '2025-06-24', 'Accepted', '2025-06-29', NULL),
('APP-2025-00208', 3, 'Acquisition', 'ACQ-12483-25', '2025-06-23', 'Accepted', '2025-06-30', NULL),
('APP-2025-00208', 4, 'Other', 'DOC-912950', '2025-06-26', 'Accepted', '2025-06-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000208', 'APP-2025-00208', '2025-06-29', 900, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00209', 'AP-00156', 'GF-00028', '2025-06-22', 'New', 'Approved', '2025-08-14', 'LC06', 'Maligaya', 'ACQ-73581-25', '2025-03-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00209', 1, 'Identity', 'DOC-545960', '2025-06-22', 'Accepted', '2025-06-28', NULL),
('APP-2025-00209', 2, 'Registration', 'REF-202833', '2025-06-27', 'Accepted', '2025-07-04', NULL),
('APP-2025-00209', 3, 'Acquisition', 'ACQ-73581-25', '2025-06-25', 'Accepted', '2025-07-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000209', 'APP-2025-00209', '2025-06-30', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00147', 'APP-2025-00209', '2025-08-16', '2025-08-16', '2026-08-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00210', 'AP-00014', 'GF-00031', '2025-06-23', 'New', 'Rejected', '2025-07-12', 'LC06', 'Maligaya', 'ACQ-99908-25', '2025-06-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00210', 1, 'Identity', 'DOC-538189', '2025-06-23', 'Accepted', '2025-06-26', NULL),
('APP-2025-00210', 2, 'Registration', 'FILE-869317', '2025-06-26', 'NeedsCorrection', '2025-06-28', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00210', 3, 'Acquisition', 'ACQ-99908-25', '2025-06-25', 'Accepted', '2025-07-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000210', 'APP-2025-00210', '2025-06-25', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00211', 'AP-00024', 'GF-00002', '2025-06-24', 'New', 'Rejected', '2025-06-30', 'LC07', 'Pulo Verde', 'ACQ-79984-25', '2025-03-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00211', 1, 'Identity', 'REF-58281', '2025-06-24', 'NeedsCorrection', '2025-06-30', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00211', 2, 'Registration', 'FILE-222146', '2025-06-27', 'Pending', NULL, NULL),
('APP-2025-00211', 3, 'Acquisition', 'ACQ-79984-25', '2025-06-27', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000211', 'APP-2025-00211', '2025-06-28', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00212', 'AP-00132', 'GF-00151', '2025-06-27', 'New', 'Rejected', '2025-07-13', 'LC02', 'San Isidro Heights', 'ACQ-95541-25', '2025-06-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00212', 1, 'Identity', 'DOC-392348', '2025-06-27', 'NeedsCorrection', '2025-07-02', 'A clearer copy of the reference portion is requested.'),
('APP-2025-00212', 2, 'Registration', 'DOC-116881', '2025-06-28', 'Pending', NULL, NULL),
('APP-2025-00212', 3, 'Acquisition', 'ACQ-95541-25', '2025-07-01', 'NeedsCorrection', '2025-07-04', 'The recorded reference must be verified with the submitted copy.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000212', 'APP-2025-00212', '2025-07-01', 1200, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00213', 'AP-00024', 'GF-00119', '2025-06-28', 'New', 'Approved', '2025-07-18', 'LC07', 'Pulo Verde', 'ACQ-25457-25', '2025-03-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00213', 1, 'Identity', 'FILE-597357', '2025-06-28', 'Accepted', '2025-06-30', NULL),
('APP-2025-00213', 2, 'Registration', 'FILE-490215', '2025-06-29', 'Accepted', '2025-07-04', NULL),
('APP-2025-00213', 3, 'Acquisition', 'ACQ-25457-25', '2025-07-03', 'Accepted', '2025-07-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000213', 'APP-2025-00213', '2025-06-28', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00214', 'AP-00013', 'GF-00023', '2025-06-29', 'New', 'Withdrawn', NULL, 'LC06', 'Maligaya', 'ACQ-52148-25', '2025-03-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00214', 1, 'Identity', 'REF-478255', '2025-06-29', 'NeedsCorrection', '2025-07-06', 'The date on the document needs clarification.'),
('APP-2025-00214', 2, 'Registration', 'REF-996750', '2025-07-01', 'Pending', NULL, NULL),
('APP-2025-00214', 3, 'Acquisition', 'ACQ-52148-25', '2025-07-04', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000214', 'APP-2025-00214', '2025-07-04', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00215', 'AP-00032', 'GF-00079', '2025-06-29', 'New', 'Rejected', '2025-07-04', 'LC08', 'San Rafael Norte', 'ACQ-62955-25', '2025-04-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00215', 1, 'Identity', 'FILE-269858', '2025-06-29', 'Pending', NULL, NULL),
('APP-2025-00215', 2, 'Registration', 'FILE-788891', '2025-06-29', 'Accepted', '2025-07-02', NULL),
('APP-2025-00215', 3, 'Acquisition', 'ACQ-62955-25', '2025-06-30', 'NeedsCorrection', '2025-07-02', 'Please provide the missing page of the supporting document.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000215', 'APP-2025-00215', '2025-07-04', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00216', 'AP-00115', 'GF-00130', '2025-07-01', 'New', 'Approved', '2025-07-09', 'LC02', 'San Isidro Heights', 'ACQ-20906-25', '2025-04-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00216', 1, 'Identity', 'DOC-228573', '2025-07-01', 'Accepted', '2025-07-04', NULL),
('APP-2025-00216', 2, 'Registration', 'DOC-836150', '2025-07-04', 'Accepted', '2025-07-09', NULL),
('APP-2025-00216', 3, 'Acquisition', 'ACQ-20906-25', '2025-07-02', 'Accepted', '2025-07-04', NULL),
('APP-2025-00216', 4, 'Other', 'REF-980800', '2025-07-01', 'Accepted', '2025-07-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000216', 'APP-2025-00216', '2025-07-08', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00148', 'APP-2025-00216', '2025-07-14', '2025-07-14', '2026-07-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00217', 'AP-00141', 'GF-00065', '2025-07-02', 'New', 'Approved', '2025-07-12', 'LC02', 'San Isidro Heights', 'ACQ-71573-25', '2025-03-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00217', 1, 'Identity', 'FILE-739006', '2025-07-02', 'Accepted', '2025-07-09', NULL),
('APP-2025-00217', 2, 'Registration', 'REF-759010', '2025-07-02', 'Accepted', '2025-07-04', NULL),
('APP-2025-00217', 3, 'Acquisition', 'ACQ-71573-25', '2025-07-03', 'Accepted', '2025-07-07', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00149', 'APP-2025-00217', '2025-07-13', '2025-07-13', '2026-07-12', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00218', 'AP-00033', 'GF-00059', '2025-07-02', 'Replacement', 'Approved', '2025-07-23', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2025-06-22', 'IR-2025-2475');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00218', 1, 'Identity', 'REF-604713', '2025-07-02', 'Accepted', '2025-07-03', NULL),
('APP-2025-00218', 2, 'Registration', 'FILE-523398', '2025-07-07', 'Accepted', '2025-07-10', NULL),
('APP-2025-00218', 3, 'Incident', 'IR-2025-2475', '2025-07-07', 'Accepted', '2025-07-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000217', 'APP-2025-00218', '2025-07-03', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00150', 'APP-2025-00218', '2025-07-25', '2025-07-25', '2026-07-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00219', 'AP-00145', 'GF-00026', '2025-07-03', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-39014-25', '2025-04-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00219', 1, 'Identity', 'FILE-405741', '2025-07-03', 'Accepted', '2025-07-06', NULL),
('APP-2025-00219', 2, 'Registration', 'FILE-554485', '2025-07-05', 'NeedsCorrection', '2025-07-08', 'The date on the document needs clarification.'),
('APP-2025-00219', 3, 'Acquisition', 'ACQ-39014-25', '2025-07-04', 'Accepted', '2025-07-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000218', 'APP-2025-00219', '2025-07-08', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00220', 'AP-00184', 'GF-00139', '2025-07-05', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-16676-25', '2025-06-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00220', 1, 'Identity', 'DOC-692802', '2025-07-05', 'NeedsCorrection', '2025-07-11', 'Please provide the missing page of the supporting document.'),
('APP-2025-00220', 2, 'Registration', 'REF-369672', '2025-07-07', 'Accepted', '2025-07-12', NULL),
('APP-2025-00220', 3, 'Acquisition', 'ACQ-16676-25', '2025-07-08', 'NeedsCorrection', '2025-07-13', 'The recorded reference must be verified with the submitted copy.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000219', 'APP-2025-00220', '2025-07-10', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00221', 'AP-00161', 'GF-00013', '2025-07-07', 'New', 'Approved', '2025-07-25', 'LC01', 'Luntian Central', 'ACQ-34211-25', '2025-04-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00221', 1, 'Identity', 'REF-537246', '2025-07-07', 'Accepted', '2025-07-11', NULL),
('APP-2025-00221', 2, 'Registration', 'REF-502926', '2025-07-07', 'Accepted', '2025-07-11', NULL),
('APP-2025-00221', 3, 'Acquisition', 'ACQ-34211-25', '2025-07-07', 'Accepted', '2025-07-09', NULL),
('APP-2025-00221', 4, 'Other', 'DOC-353177', '2025-07-09', 'Accepted', '2025-07-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000220', 'APP-2025-00221', '2025-07-19', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00222', 'AP-00116', 'GF-00124', '2025-07-07', 'New', 'Approved', '2025-07-19', 'LC04', 'Bagong Silangan', 'ACQ-63120-25', '2025-03-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00222', 1, 'Identity', 'REF-315751', '2025-07-07', 'Accepted', '2025-07-14', NULL),
('APP-2025-00222', 2, 'Registration', 'DOC-291238', '2025-07-10', 'Accepted', '2025-07-14', NULL),
('APP-2025-00222', 3, 'Acquisition', 'ACQ-63120-25', '2025-07-09', 'Accepted', '2025-07-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000221', 'APP-2025-00222', '2025-07-18', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00151', 'APP-2025-00222', '2025-07-24', '2025-07-24', '2026-07-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00223', 'AP-00044', 'GF-00011', '2025-07-09', 'New', 'Approved', '2025-07-24', 'LC01', 'Luntian Central', 'ACQ-79398-25', '2025-06-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00223', 1, 'Identity', 'FILE-242626', '2025-07-09', 'Accepted', '2025-07-14', NULL),
('APP-2025-00223', 2, 'Registration', 'DOC-937400', '2025-07-13', 'Accepted', '2025-07-19', NULL),
('APP-2025-00223', 3, 'Acquisition', 'ACQ-79398-25', '2025-07-09', 'Accepted', '2025-07-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000222', 'APP-2025-00223', '2025-07-18', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00152', 'APP-2025-00223', '2025-07-29', '2025-07-29', '2026-07-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00224', 'AP-00023', 'GF-00157', '2025-07-10', 'New', 'Rejected', '2025-07-19', 'LC01', 'Luntian Central', 'ACQ-62883-25', '2025-06-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00224', 1, 'Identity', 'FILE-587442', '2025-07-10', 'Pending', NULL, NULL),
('APP-2025-00224', 2, 'Registration', 'DOC-807736', '2025-07-14', 'Accepted', '2025-07-17', NULL),
('APP-2025-00224', 3, 'Acquisition', 'ACQ-62883-25', '2025-07-13', 'NeedsCorrection', '2025-07-17', 'The date on the document needs clarification.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00225', 'AP-00081', 'GF-00152', '2025-07-11', 'New', 'Approved', '2025-07-18', 'LC02', 'San Isidro Heights', 'ACQ-32131-25', '2025-04-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00225', 1, 'Identity', 'REF-39928', '2025-07-11', 'Accepted', '2025-07-12', NULL),
('APP-2025-00225', 2, 'Registration', 'DOC-493798', '2025-07-15', 'Accepted', '2025-07-18', NULL),
('APP-2025-00225', 3, 'Acquisition', 'ACQ-32131-25', '2025-07-13', 'Accepted', '2025-07-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000223', 'APP-2025-00225', '2025-07-17', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00153', 'APP-2025-00225', '2025-07-23', '2025-07-23', '2026-07-22', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00226', 'AP-00107', 'GF-00103', '2025-07-11', 'New', 'Rejected', '2025-07-26', 'LC06', 'Maligaya', 'ACQ-50534-25', '2025-04-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00226', 1, 'Identity', 'REF-610354', '2025-07-11', 'Accepted', '2025-07-14', NULL),
('APP-2025-00226', 2, 'Registration', 'DOC-613205', '2025-07-14', 'Accepted', '2025-07-15', NULL),
('APP-2025-00226', 3, 'Acquisition', 'ACQ-50534-25', '2025-07-11', 'Accepted', '2025-07-17', NULL),
('APP-2025-00226', 4, 'Other', 'DOC-815788', '2025-07-14', 'Accepted', '2025-07-17', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00227', 'AP-00006', 'GF-00036', '2025-07-15', 'New', 'Approved', '2025-08-06', 'LC03', 'Mabini East', 'ACQ-55652-25', '2025-04-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00227', 1, 'Identity', 'DOC-516550', '2025-07-15', 'Accepted', '2025-07-22', NULL),
('APP-2025-00227', 2, 'Registration', 'REF-228291', '2025-07-20', 'Accepted', '2025-07-26', NULL),
('APP-2025-00227', 3, 'Acquisition', 'ACQ-55652-25', '2025-07-17', 'Accepted', '2025-07-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000224', 'APP-2025-00227', '2025-07-23', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00154', 'APP-2025-00227', '2025-08-07', '2025-08-07', '2026-08-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00228', 'AP-00019', 'GF-00153', '2025-07-16', 'New', 'Approved', '2025-07-21', 'LC04', 'Bagong Silangan', 'ACQ-96785-25', '2025-04-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00228', 1, 'Identity', 'FILE-793972', '2025-07-16', 'Accepted', '2025-07-21', NULL),
('APP-2025-00228', 2, 'Registration', 'FILE-942501', '2025-07-19', 'Accepted', '2025-07-21', NULL),
('APP-2025-00228', 3, 'Acquisition', 'ACQ-96785-25', '2025-07-16', 'Accepted', '2025-07-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000225', 'APP-2025-00228', '2025-07-21', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00155', 'APP-2025-00228', '2025-07-25', '2025-07-25', '2026-07-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00229', 'AP-00084', 'GF-00077', '2025-07-16', 'New', 'Approved', '2025-07-23', 'LC03', 'Mabini East', 'ACQ-17160-25', '2025-05-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00229', 1, 'Identity', 'DOC-749465', '2025-07-16', 'Accepted', '2025-07-23', NULL),
('APP-2025-00229', 2, 'Registration', 'FILE-957164', '2025-07-16', 'Accepted', '2025-07-19', NULL),
('APP-2025-00229', 3, 'Acquisition', 'ACQ-17160-25', '2025-07-21', 'Accepted', '2025-07-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000226', 'APP-2025-00229', '2025-07-23', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00156', 'APP-2025-00229', '2025-07-23', '2025-07-23', '2026-07-22', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00230', 'AP-00049', 'GF-00142', '2025-07-16', 'New', 'Approved', '2025-07-30', 'LC04', 'Bagong Silangan', 'ACQ-68274-25', '2025-06-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00230', 1, 'Identity', 'REF-363716', '2025-07-16', 'Accepted', '2025-07-21', NULL),
('APP-2025-00230', 2, 'Registration', 'FILE-886902', '2025-07-17', 'Accepted', '2025-07-19', NULL),
('APP-2025-00230', 3, 'Acquisition', 'ACQ-68274-25', '2025-07-21', 'Accepted', '2025-07-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000227', 'APP-2025-00230', '2025-07-16', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00157', 'APP-2025-00230', '2025-08-04', '2025-08-04', '2026-08-03', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00231', 'AP-00180', 'GF-00145', '2025-07-17', 'New', 'Approved', '2025-08-10', 'LC07', 'Pulo Verde', 'ACQ-61534-25', '2025-03-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00231', 1, 'Identity', 'REF-446441', '2025-07-17', 'Accepted', '2025-07-18', NULL),
('APP-2025-00231', 2, 'Registration', 'REF-194488', '2025-07-17', 'Accepted', '2025-07-20', NULL),
('APP-2025-00231', 3, 'Acquisition', 'ACQ-61534-25', '2025-07-19', 'Accepted', '2025-07-23', NULL),
('APP-2025-00231', 4, 'Other', 'REF-798046', '2025-07-20', 'Accepted', '2025-07-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000228', 'APP-2025-00231', '2025-07-22', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00158', 'APP-2025-00231', '2025-08-12', '2025-08-12', '2026-08-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00232', 'AP-00170', 'GF-00030', '2025-07-17', 'New', 'Approved', '2025-08-31', 'LC03', 'Mabini East', 'ACQ-51821-25', '2025-06-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00232', 1, 'Identity', 'FILE-560424', '2025-07-17', 'Accepted', '2025-07-22', NULL),
('APP-2025-00232', 2, 'Registration', 'FILE-602001', '2025-07-21', 'Accepted', '2025-07-22', NULL),
('APP-2025-00232', 3, 'Acquisition', 'ACQ-51821-25', '2025-07-17', 'Accepted', '2025-07-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000229', 'APP-2025-00232', '2025-07-22', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00159', 'APP-2025-00232', '2025-09-02', '2025-09-02', '2026-09-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00233', 'AP-00055', 'GF-00126', '2025-07-18', 'New', 'Approved', '2025-07-23', 'LC01', 'Luntian Central', 'ACQ-63535-25', '2025-05-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00233', 1, 'Identity', 'DOC-58258', '2025-07-18', 'Accepted', '2025-07-23', NULL),
('APP-2025-00233', 2, 'Registration', 'DOC-652880', '2025-07-23', 'Accepted', '2025-07-23', NULL),
('APP-2025-00233', 3, 'Acquisition', 'ACQ-63535-25', '2025-07-19', 'Accepted', '2025-07-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000230', 'APP-2025-00233', '2025-07-23', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00160', 'APP-2025-00233', '2025-07-28', '2025-07-28', '2026-07-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00234', 'AP-00080', 'GF-00157', '2025-07-18', 'New', 'Approved', '2025-08-07', 'LC02', 'San Isidro Heights', 'ACQ-25342-25', '2025-05-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00234', 1, 'Identity', 'DOC-172076', '2025-07-18', 'Accepted', '2025-07-24', NULL),
('APP-2025-00234', 2, 'Registration', 'REF-937319', '2025-07-20', 'Accepted', '2025-07-23', NULL),
('APP-2025-00234', 3, 'Acquisition', 'ACQ-25342-25', '2025-07-21', 'Accepted', '2025-07-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000231', 'APP-2025-00234', '2025-07-26', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00161', 'APP-2025-00234', '2025-08-11', '2025-08-11', '2026-08-10', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00235', 'AP-00174', 'GF-00054', '2025-07-20', 'New', 'Rejected', '2025-08-09', 'LC03', 'Mabini East', 'ACQ-55903-25', '2025-04-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00235', 1, 'Identity', 'REF-604280', '2025-07-20', 'NeedsCorrection', '2025-07-26', 'The submitted name requires clarification against the application.'),
('APP-2025-00235', 2, 'Registration', 'DOC-733929', '2025-07-22', 'NeedsCorrection', '2025-07-23', 'A clearer copy of the reference portion is requested.'),
('APP-2025-00235', 3, 'Acquisition', 'ACQ-55903-25', '2025-07-25', 'NeedsCorrection', '2025-07-31', 'Please provide the missing page of the supporting document.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000232', 'APP-2025-00235', '2025-07-21', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00236', 'AP-00049', 'GF-00041', '2025-07-24', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-53484-25', '2025-05-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00236', 1, 'Identity', 'DOC-634888', '2025-07-24', 'Accepted', '2025-07-29', NULL),
('APP-2025-00236', 2, 'Registration', 'DOC-708683', '2025-07-26', 'Pending', NULL, NULL),
('APP-2025-00236', 3, 'Acquisition', 'ACQ-53484-25', '2025-07-24', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00237', 'AP-00163', 'GF-00107', '2025-07-27', 'New', 'Rejected', '2025-07-30', 'LC01', 'Luntian Central', 'ACQ-63604-25', '2025-07-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00237', 1, 'Identity', 'DOC-27111', '2025-07-27', 'NeedsCorrection', '2025-07-29', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00237', 2, 'Registration', 'DOC-945282', '2025-07-30', 'NeedsCorrection', '2025-07-30', 'Please provide the missing page of the supporting document.'),
('APP-2025-00237', 3, 'Acquisition', 'ACQ-63604-25', '2025-07-30', 'Accepted', '2025-07-30', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00238', 'AP-00170', 'GF-00020', '2025-07-27', 'New', 'Approved', '2025-08-09', 'LC03', 'Mabini East', 'ACQ-51969-25', '2025-04-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00238', 1, 'Identity', 'REF-956435', '2025-07-27', 'Accepted', '2025-08-03', NULL),
('APP-2025-00238', 2, 'Registration', 'REF-743521', '2025-07-30', 'Accepted', '2025-07-31', NULL),
('APP-2025-00238', 3, 'Acquisition', 'ACQ-51969-25', '2025-08-01', 'Accepted', '2025-08-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000233', 'APP-2025-00238', '2025-08-02', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00162', 'APP-2025-00238', '2025-08-13', '2025-08-13', '2026-08-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00239', 'AP-00145', 'GF-00033', '2025-07-30', 'New', 'Approved', '2025-08-18', 'LC04', 'Bagong Silangan', 'ACQ-77817-25', '2025-07-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00239', 1, 'Identity', 'FILE-487938', '2025-07-30', 'Accepted', '2025-08-03', NULL),
('APP-2025-00239', 2, 'Registration', 'REF-839754', '2025-08-03', 'Accepted', '2025-08-10', NULL),
('APP-2025-00239', 3, 'Acquisition', 'ACQ-77817-25', '2025-08-01', 'Accepted', '2025-08-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000234', 'APP-2025-00239', '2025-07-30', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00163', 'APP-2025-00239', '2025-08-19', '2025-08-19', '2026-08-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00240', 'AP-00004', 'GF-00100', '2025-08-05', 'New', 'Approved', '2025-08-26', 'LC01', 'Luntian Central', 'ACQ-47175-25', '2025-06-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00240', 1, 'Identity', 'DOC-850513', '2025-08-05', 'Accepted', '2025-08-08', NULL),
('APP-2025-00240', 2, 'Registration', 'FILE-524547', '2025-08-10', 'Accepted', '2025-08-17', NULL),
('APP-2025-00240', 3, 'Acquisition', 'ACQ-47175-25', '2025-08-10', 'Accepted', '2025-08-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000235', 'APP-2025-00240', '2025-08-14', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00164', 'APP-2025-00240', '2025-08-26', '2025-08-26', '2026-08-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00241', 'AP-00080', 'GF-00048', '2025-08-05', 'New', 'Approved', '2025-08-17', 'LC02', 'San Isidro Heights', 'ACQ-64299-25', '2025-07-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00241', 1, 'Identity', 'FILE-910277', '2025-08-05', 'Accepted', '2025-08-08', NULL),
('APP-2025-00241', 2, 'Registration', 'DOC-554525', '2025-08-06', 'Accepted', '2025-08-13', NULL),
('APP-2025-00241', 3, 'Acquisition', 'ACQ-64299-25', '2025-08-05', 'Accepted', '2025-08-07', NULL),
('APP-2025-00241', 4, 'Other', 'REF-514516', '2025-08-06', 'Accepted', '2025-08-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000236', 'APP-2025-00241', '2025-08-16', 600, 'Online'),
('OR-2025-000237', 'APP-2025-00241', '2025-08-13', 100, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00165', 'APP-2025-00241', '2025-08-18', '2025-08-18', '2026-08-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00242', 'AP-00122', 'GF-00148', '2025-08-05', 'New', 'Approved', '2025-08-23', 'LC03', 'Mabini East', 'ACQ-49219-25', '2025-07-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00242', 1, 'Identity', 'FILE-265158', '2025-08-05', 'Accepted', '2025-08-09', NULL),
('APP-2025-00242', 2, 'Registration', 'FILE-650146', '2025-08-09', 'Accepted', '2025-08-14', NULL),
('APP-2025-00242', 3, 'Acquisition', 'ACQ-49219-25', '2025-08-05', 'Accepted', '2025-08-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000238', 'APP-2025-00242', '2025-08-15', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00166', 'APP-2025-00242', '2025-08-28', '2025-08-28', '2026-08-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00243', 'AP-00116', 'GF-00050', '2025-08-07', 'New', 'Rejected', '2025-08-11', 'LC04', 'Bagong Silangan', 'ACQ-18142-25', '2025-07-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00243', 1, 'Identity', 'DOC-694625', '2025-08-07', 'NeedsCorrection', '2025-08-11', 'The date on the document needs clarification.'),
('APP-2025-00243', 2, 'Registration', 'REF-97636', '2025-08-11', 'Accepted', '2025-08-11', NULL),
('APP-2025-00243', 3, 'Acquisition', 'ACQ-18142-25', '2025-08-11', 'NeedsCorrection', '2025-08-11', 'The submitted name requires clarification against the application.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000239', 'APP-2025-00243', '2025-08-11', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00244', 'AP-00181', 'GF-00050', '2025-08-08', 'New', 'Approved', '2025-08-26', 'LC06', 'Maligaya', 'ACQ-88511-25', '2025-04-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00244', 1, 'Identity', 'FILE-843975', '2025-08-08', 'Accepted', '2025-08-11', NULL),
('APP-2025-00244', 2, 'Registration', 'DOC-133282', '2025-08-10', 'Accepted', '2025-08-12', NULL),
('APP-2025-00244', 3, 'Acquisition', 'ACQ-88511-25', '2025-08-10', 'Accepted', '2025-08-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000240', 'APP-2025-00244', '2025-08-20', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00167', 'APP-2025-00244', '2025-08-29', '2025-08-29', '2026-08-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00245', 'AP-00164', 'GF-00160', '2025-08-09', 'New', 'Approved', '2025-08-18', 'LC01', 'Luntian Central', 'ACQ-60109-25', '2025-06-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00245', 1, 'Identity', 'DOC-791526', '2025-08-09', 'Accepted', '2025-08-14', NULL),
('APP-2025-00245', 2, 'Registration', 'REF-578961', '2025-08-13', 'Accepted', '2025-08-18', NULL),
('APP-2025-00245', 3, 'Acquisition', 'ACQ-60109-25', '2025-08-09', 'Accepted', '2025-08-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000241', 'APP-2025-00245', '2025-08-09', 750, 'Online'),
('OR-2025-000242', 'APP-2025-00245', '2025-08-18', 250, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00168', 'APP-2025-00245', '2025-08-18', '2025-08-18', '2026-08-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00246', 'AP-00108', 'GF-00022', '2025-08-09', 'Replacement', 'Approved', '2025-09-02', 'LC02', 'San Isidro Heights', NULL, NULL, NULL, NULL, '2025-07-20', 'IR-2025-1301');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00246', 1, 'Identity', 'REF-333040', '2025-08-09', 'Accepted', '2025-08-15', NULL),
('APP-2025-00246', 2, 'Registration', 'FILE-46019', '2025-08-13', 'Accepted', '2025-08-17', NULL),
('APP-2025-00246', 3, 'Incident', 'IR-2025-1301', '2025-08-12', 'Accepted', '2025-08-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000243', 'APP-2025-00246', '2025-08-19', 750, 'Cash'),
('OR-2025-000244', 'APP-2025-00246', '2025-08-16', 150, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00169', 'APP-2025-00246', '2025-09-06', '2025-09-06', '2026-09-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00247', 'AP-00139', 'GF-00132', '2025-08-10', 'New', 'Approved', '2025-08-18', 'LC04', 'Bagong Silangan', 'ACQ-32864-25', '2025-07-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00247', 1, 'Identity', 'REF-636128', '2025-08-10', 'Accepted', '2025-08-12', NULL),
('APP-2025-00247', 2, 'Registration', 'DOC-176159', '2025-08-14', 'Accepted', '2025-08-18', NULL),
('APP-2025-00247', 3, 'Acquisition', 'ACQ-32864-25', '2025-08-11', 'Accepted', '2025-08-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000245', 'APP-2025-00247', '2025-08-18', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00170', 'APP-2025-00247', '2025-08-20', '2025-08-20', '2026-08-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00248', 'AP-00013', 'GF-00047', '2025-08-13', 'New', 'Withdrawn', NULL, 'LC06', 'Maligaya', 'ACQ-47190-25', '2025-05-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00248', 1, 'Identity', 'REF-592774', '2025-08-13', 'Accepted', '2025-08-19', NULL),
('APP-2025-00248', 2, 'Registration', 'FILE-482312', '2025-08-15', 'NeedsCorrection', '2025-08-16', 'Please provide the missing page of the supporting document.'),
('APP-2025-00248', 3, 'Acquisition', 'ACQ-47190-25', '2025-08-16', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000246', 'APP-2025-00248', '2025-08-13', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00249', 'AP-00004', 'GF-00071', '2025-08-14', 'New', 'Withdrawn', NULL, 'LC01', 'Luntian Central', 'ACQ-57799-25', '2025-06-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00249', 1, 'Identity', 'FILE-863700', '2025-08-14', 'NeedsCorrection', '2025-08-16', 'The submitted name requires clarification against the application.'),
('APP-2025-00249', 2, 'Registration', 'FILE-643173', '2025-08-16', 'Pending', NULL, NULL),
('APP-2025-00249', 3, 'Acquisition', 'ACQ-57799-25', '2025-08-19', 'NeedsCorrection', '2025-08-25', 'The recorded reference must be verified with the submitted copy.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000247', 'APP-2025-00249', '2025-08-14', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00250', 'AP-00174', 'GF-00101', '2025-08-16', 'New', 'Approved', '2025-08-25', 'LC03', 'Mabini East', 'ACQ-24976-25', '2025-08-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00250', 1, 'Identity', 'FILE-504839', '2025-08-16', 'Accepted', '2025-08-18', NULL),
('APP-2025-00250', 2, 'Registration', 'FILE-252639', '2025-08-17', 'Accepted', '2025-08-18', NULL),
('APP-2025-00250', 3, 'Acquisition', 'ACQ-24976-25', '2025-08-20', 'Accepted', '2025-08-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000248', 'APP-2025-00250', '2025-08-17', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00171', 'APP-2025-00250', '2025-08-27', '2025-08-27', '2026-08-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00251', 'AP-00142', 'GF-00099', '2025-08-16', 'New', 'Withdrawn', NULL, 'LC07', 'Pulo Verde', 'ACQ-61798-25', '2025-05-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00251', 1, 'Identity', 'FILE-583569', '2025-08-16', 'Accepted', '2025-08-20', NULL),
('APP-2025-00251', 2, 'Registration', 'FILE-993179', '2025-08-16', 'NeedsCorrection', '2025-08-19', 'Please provide the missing page of the supporting document.'),
('APP-2025-00251', 3, 'Acquisition', 'ACQ-61798-25', '2025-08-19', 'Accepted', '2025-08-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000249', 'APP-2025-00251', '2025-08-19', 600, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00252', 'AP-00008', 'GF-00104', '2025-08-17', 'New', 'Approved', '2025-08-29', 'LC02', 'San Isidro Heights', 'ACQ-26910-25', '2025-06-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00252', 1, 'Identity', 'DOC-923991', '2025-08-17', 'Accepted', '2025-08-24', NULL),
('APP-2025-00252', 2, 'Registration', 'FILE-899915', '2025-08-17', 'Accepted', '2025-08-19', NULL),
('APP-2025-00252', 3, 'Acquisition', 'ACQ-26910-25', '2025-08-18', 'Accepted', '2025-08-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000250', 'APP-2025-00252', '2025-08-25', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00172', 'APP-2025-00252', '2025-09-03', '2025-09-03', '2026-09-02', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00253', 'AP-00126', 'GF-00095', '2025-08-18', 'New', 'Approved', '2025-09-25', 'LC05', 'Santa Elena', 'ACQ-91703-25', '2025-06-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00253', 1, 'Identity', 'DOC-917374', '2025-08-18', 'Accepted', '2025-08-21', NULL),
('APP-2025-00253', 2, 'Registration', 'DOC-565295', '2025-08-18', 'Accepted', '2025-08-20', NULL),
('APP-2025-00253', 3, 'Acquisition', 'ACQ-91703-25', '2025-08-22', 'Accepted', '2025-08-24', NULL),
('APP-2025-00253', 4, 'Other', 'FILE-821136', '2025-08-21', 'Accepted', '2025-08-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000251', 'APP-2025-00253', '2025-08-26', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00173', 'APP-2025-00253', '2025-09-27', '2025-09-27', '2026-09-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00254', 'AP-00181', 'GF-00005', '2025-08-20', 'New', 'Approved', '2025-10-11', 'LC07', 'Pulo Verde', 'ACQ-79693-25', '2025-05-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00254', 1, 'Identity', 'REF-864375', '2025-08-20', 'Accepted', '2025-08-22', NULL),
('APP-2025-00254', 2, 'Registration', 'REF-569131', '2025-08-24', 'Accepted', '2025-08-26', NULL),
('APP-2025-00254', 3, 'Acquisition', 'ACQ-79693-25', '2025-08-21', 'Accepted', '2025-08-22', NULL),
('APP-2025-00254', 4, 'Other', 'FILE-999431', '2025-08-22', 'Accepted', '2025-08-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000252', 'APP-2025-00254', '2025-09-01', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00174', 'APP-2025-00254', '2025-10-11', '2025-10-11', '2026-10-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00255', 'AP-00128', 'GF-00117', '2025-08-20', 'New', 'Approved', '2025-08-23', 'LC01', 'Luntian Central', 'ACQ-42844-25', '2025-08-05', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00255', 1, 'Identity', 'FILE-449778', '2025-08-20', 'Accepted', '2025-08-23', NULL),
('APP-2025-00255', 2, 'Registration', 'REF-237033', '2025-08-20', 'Accepted', '2025-08-23', NULL),
('APP-2025-00255', 3, 'Acquisition', 'ACQ-42844-25', '2025-08-20', 'Accepted', '2025-08-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000253', 'APP-2025-00255', '2025-08-23', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00175', 'APP-2025-00255', '2025-08-28', '2025-08-28', '2026-08-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00256', 'AP-00034', 'GF-00138', '2025-08-22', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-57449-25', '2025-07-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00256', 1, 'Identity', 'DOC-720116', '2025-08-22', 'Pending', NULL, NULL),
('APP-2025-00256', 2, 'Registration', 'FILE-606082', '2025-08-22', 'Accepted', '2025-08-26', NULL),
('APP-2025-00256', 3, 'Acquisition', 'ACQ-57449-25', '2025-08-27', 'Accepted', '2025-09-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000254', 'APP-2025-00256', '2025-08-30', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00257', 'AP-00003', 'GF-00113', '2025-08-23', 'New', 'Approved', '2025-09-16', 'LC05', 'Santa Elena', 'ACQ-87887-25', '2025-08-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00257', 1, 'Identity', 'DOC-633860', '2025-08-23', 'Accepted', '2025-08-26', NULL),
('APP-2025-00257', 2, 'Registration', 'FILE-703014', '2025-08-28', 'Accepted', '2025-08-31', NULL),
('APP-2025-00257', 3, 'Acquisition', 'ACQ-87887-25', '2025-08-23', 'Accepted', '2025-08-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000255', 'APP-2025-00257', '2025-08-26', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00176', 'APP-2025-00257', '2025-09-20', '2025-09-20', '2026-09-19', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00258', 'AP-00078', 'GF-00139', '2025-08-26', 'New', 'Rejected', '2025-09-18', 'LC03', 'Mabini East', 'ACQ-15711-25', '2025-06-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00258', 1, 'Identity', 'REF-359761', '2025-08-26', 'Accepted', '2025-08-30', NULL),
('APP-2025-00258', 2, 'Registration', 'DOC-583825', '2025-08-31', 'Accepted', '2025-09-07', NULL),
('APP-2025-00258', 3, 'Acquisition', 'ACQ-15711-25', '2025-08-31', 'NeedsCorrection', '2025-09-03', 'The date on the document needs clarification.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000256', 'APP-2025-00258', '2025-09-04', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00259', 'AP-00177', 'GF-00115', '2025-08-27', 'New', 'UnderReview', NULL, 'LC05', 'Santa Elena', 'ACQ-20130-25', '2025-07-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00259', 1, 'Identity', 'DOC-730384', '2025-08-27', 'Accepted', '2025-08-30', NULL),
('APP-2025-00259', 2, 'Registration', 'REF-67657', '2025-08-30', 'NeedsCorrection', '2025-09-02', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00259', 3, 'Acquisition', 'ACQ-20130-25', '2025-08-27', 'Pending', NULL, NULL),
('APP-2025-00259', 4, 'Other', 'REF-653399', '2025-08-29', 'Accepted', '2025-09-03', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00260', 'AP-00187', 'GF-00078', '2025-08-28', 'New', 'Approved', '2025-09-15', 'LC06', 'Maligaya', 'ACQ-26424-25', '2025-08-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00260', 1, 'Identity', 'REF-254431', '2025-08-28', 'Accepted', '2025-08-31', NULL),
('APP-2025-00260', 2, 'Registration', 'DOC-741640', '2025-08-28', 'Accepted', '2025-09-02', NULL),
('APP-2025-00260', 3, 'Acquisition', 'ACQ-26424-25', '2025-08-28', 'Accepted', '2025-08-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000257', 'APP-2025-00260', '2025-08-31', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00177', 'APP-2025-00260', '2025-09-19', '2025-09-19', '2026-09-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00261', 'AP-00029', 'GF-00094', '2025-08-29', 'New', 'Approved', '2025-09-19', 'LC02', 'San Isidro Heights', 'ACQ-90625-25', '2025-06-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00261', 1, 'Identity', 'REF-196687', '2025-08-29', 'Accepted', '2025-09-05', NULL),
('APP-2025-00261', 2, 'Registration', 'FILE-664185', '2025-08-31', 'Accepted', '2025-09-05', NULL),
('APP-2025-00261', 3, 'Acquisition', 'ACQ-90625-25', '2025-08-29', 'Accepted', '2025-09-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000258', 'APP-2025-00261', '2025-09-02', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00178', 'APP-2025-00261', '2025-09-23', '2025-09-23', '2026-09-22', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00262', 'AP-00111', 'GF-00012', '2025-08-30', 'New', 'Approved', '2025-09-10', 'LC05', 'Santa Elena', 'ACQ-41870-25', '2025-08-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00262', 1, 'Identity', 'FILE-444824', '2025-08-30', 'Accepted', '2025-09-04', NULL),
('APP-2025-00262', 2, 'Registration', 'FILE-586397', '2025-09-02', 'Accepted', '2025-09-04', NULL),
('APP-2025-00262', 3, 'Acquisition', 'ACQ-41870-25', '2025-09-01', 'Accepted', '2025-09-05', NULL),
('APP-2025-00262', 4, 'Other', 'REF-843169', '2025-09-01', 'Accepted', '2025-09-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000259', 'APP-2025-00262', '2025-09-05', 350, 'Cash'),
('OR-2025-000260', 'APP-2025-00262', '2025-09-06', 100, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00179', 'APP-2025-00262', '2025-09-14', '2025-09-14', '2026-09-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00263', 'AP-00074', 'GF-00019', '2025-08-31', 'New', 'Approved', '2025-10-30', 'LC08', 'San Rafael Norte', 'ACQ-51006-25', '2025-07-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00263', 1, 'Identity', 'FILE-188707', '2025-08-31', 'Accepted', '2025-09-06', NULL),
('APP-2025-00263', 2, 'Registration', 'DOC-361329', '2025-08-31', 'Accepted', '2025-09-01', NULL),
('APP-2025-00263', 3, 'Acquisition', 'ACQ-51006-25', '2025-09-04', 'Accepted', '2025-09-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000261', 'APP-2025-00263', '2025-09-07', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00180', 'APP-2025-00263', '2025-10-30', '2025-10-30', '2026-10-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00264', 'AP-00021', 'GF-00118', '2025-09-01', 'New', 'Approved', '2025-09-08', 'LC03', 'Mabini East', 'ACQ-82696-25', '2025-08-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00264', 1, 'Identity', 'DOC-654467', '2025-09-01', 'Accepted', '2025-09-07', NULL),
('APP-2025-00264', 2, 'Registration', 'REF-149136', '2025-09-06', 'Accepted', '2025-09-08', NULL),
('APP-2025-00264', 3, 'Acquisition', 'ACQ-82696-25', '2025-09-02', 'Accepted', '2025-09-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000262', 'APP-2025-00264', '2025-09-08', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00181', 'APP-2025-00264', '2025-09-09', '2025-09-09', '2026-09-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00265', 'AP-00189', 'GF-00075', '2025-09-01', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-71962-25', '2025-06-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00265', 1, 'Identity', 'REF-417220', '2025-09-01', 'Accepted', '2025-09-04', NULL),
('APP-2025-00265', 2, 'Registration', 'FILE-301364', '2025-09-03', 'NeedsCorrection', '2025-09-10', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00265', 3, 'Acquisition', 'ACQ-71962-25', '2025-09-03', 'NeedsCorrection', '2025-09-10', 'The date on the document needs clarification.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000263', 'APP-2025-00265', '2025-09-10', 450, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00266', 'AP-00011', 'GF-00046', '2025-09-02', 'New', 'Rejected', '2025-10-24', 'LC03', 'Mabini East', 'ACQ-19423-25', '2025-06-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00266', 1, 'Identity', 'REF-788117', '2025-09-02', 'Accepted', '2025-09-04', NULL),
('APP-2025-00266', 2, 'Registration', 'DOC-950551', '2025-09-02', 'Pending', NULL, NULL),
('APP-2025-00266', 3, 'Acquisition', 'ACQ-19423-25', '2025-09-04', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00267', 'AP-00096', 'GF-00074', '2025-09-02', 'New', 'Approved', '2025-09-16', 'LC06', 'Maligaya', 'ACQ-49079-25', '2025-05-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00267', 1, 'Identity', 'REF-204900', '2025-09-02', 'Accepted', '2025-09-05', NULL),
('APP-2025-00267', 2, 'Registration', 'DOC-284582', '2025-09-04', 'Accepted', '2025-09-05', NULL),
('APP-2025-00267', 3, 'Acquisition', 'ACQ-49079-25', '2025-09-03', 'Accepted', '2025-09-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000264', 'APP-2025-00267', '2025-09-12', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00182', 'APP-2025-00267', '2025-09-20', '2025-09-20', '2026-09-19', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00268', 'AP-00044', 'GF-00031', '2025-09-02', 'Renewal', 'Approved', '2025-09-09', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00049', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00268', 1, 'Identity', 'REF-106359', '2025-09-02', 'Accepted', '2025-09-08', NULL),
('APP-2025-00268', 2, 'Registration', 'DOC-388258', '2025-09-03', 'Accepted', '2025-09-09', NULL),
('APP-2025-00268', 3, 'PriorPermit', 'PM-2025-00049', '2025-09-02', 'Accepted', '2025-09-09', NULL),
('APP-2025-00268', 4, 'Other', 'REF-300097', '2025-09-03', 'Accepted', '2025-09-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000265', 'APP-2025-00268', '2025-09-09', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00183', 'APP-2025-00268', '2025-09-14', '2025-09-14', '2026-09-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00269', 'AP-00181', 'GF-00157', '2025-09-03', 'New', 'Approved', '2025-09-25', 'LC05', 'Santa Elena', 'ACQ-85844-25', '2025-09-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00269', 1, 'Identity', 'REF-844168', '2025-09-03', 'Accepted', '2025-09-06', NULL),
('APP-2025-00269', 2, 'Registration', 'FILE-590664', '2025-09-04', 'Accepted', '2025-09-11', NULL),
('APP-2025-00269', 3, 'Acquisition', 'ACQ-85844-25', '2025-09-06', 'Accepted', '2025-09-11', NULL),
('APP-2025-00269', 4, 'Other', 'DOC-835510', '2025-09-08', 'Accepted', '2025-09-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000266', 'APP-2025-00269', '2025-09-12', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00270', 'AP-00166', 'GF-00016', '2025-09-06', 'New', 'Approved', '2025-09-10', 'LC05', 'Santa Elena', 'ACQ-67957-25', '2025-08-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00270', 1, 'Identity', 'REF-169240', '2025-09-06', 'Accepted', '2025-09-09', NULL),
('APP-2025-00270', 2, 'Registration', 'REF-731564', '2025-09-07', 'Accepted', '2025-09-10', NULL),
('APP-2025-00270', 3, 'Acquisition', 'ACQ-67957-25', '2025-09-09', 'Accepted', '2025-09-10', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00184', 'APP-2025-00270', '2025-09-14', '2025-09-14', '2026-09-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00271', 'AP-00024', 'GF-00112', '2025-09-06', 'New', 'Approved', '2025-09-30', 'LC08', 'San Rafael Norte', 'ACQ-23765-25', '2025-09-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00271', 1, 'Identity', 'REF-696006', '2025-09-06', 'Accepted', '2025-09-11', NULL),
('APP-2025-00271', 2, 'Registration', 'REF-114323', '2025-09-08', 'Accepted', '2025-09-10', NULL),
('APP-2025-00271', 3, 'Acquisition', 'ACQ-23765-25', '2025-09-07', 'Accepted', '2025-09-11', NULL),
('APP-2025-00271', 4, 'Other', 'REF-255862', '2025-09-09', 'Accepted', '2025-09-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000267', 'APP-2025-00271', '2025-09-06', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00185', 'APP-2025-00271', '2025-10-03', '2025-10-03', '2026-10-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00272', 'AP-00111', 'GF-00106', '2025-09-07', 'New', 'Rejected', '2025-09-16', 'LC05', 'Santa Elena', 'ACQ-12941-25', '2025-08-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00272', 1, 'Identity', 'REF-834358', '2025-09-07', 'Accepted', '2025-09-12', NULL),
('APP-2025-00272', 2, 'Registration', 'DOC-165404', '2025-09-08', 'Accepted', '2025-09-13', NULL),
('APP-2025-00272', 3, 'Acquisition', 'ACQ-12941-25', '2025-09-09', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00273', 'AP-00060', 'GF-00109', '2025-09-08', 'New', 'Approved', '2025-11-03', 'LC02', 'San Isidro Heights', 'ACQ-57925-25', '2025-05-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00273', 1, 'Identity', 'FILE-609627', '2025-09-08', 'Accepted', '2025-09-14', NULL),
('APP-2025-00273', 2, 'Registration', 'DOC-920529', '2025-09-10', 'Accepted', '2025-09-16', NULL),
('APP-2025-00273', 3, 'Acquisition', 'ACQ-57925-25', '2025-09-08', 'Accepted', '2025-09-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000268', 'APP-2025-00273', '2025-09-15', 1200, 'BankTransfer'),
('OR-2025-000269', 'APP-2025-00273', '2025-09-19', 200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00186', 'APP-2025-00273', '2025-11-04', '2025-11-04', '2026-11-03', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00274', 'AP-00156', 'GF-00002', '2025-09-09', 'New', 'Approved', '2025-09-27', 'LC06', 'Maligaya', 'ACQ-47502-25', '2025-08-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00274', 1, 'Identity', 'REF-181420', '2025-09-09', 'Accepted', '2025-09-11', NULL),
('APP-2025-00274', 2, 'Registration', 'REF-533249', '2025-09-13', 'Accepted', '2025-09-19', NULL),
('APP-2025-00274', 3, 'Acquisition', 'ACQ-47502-25', '2025-09-13', 'Accepted', '2025-09-20', NULL),
('APP-2025-00274', 4, 'Other', 'DOC-588325', '2025-09-09', 'Accepted', '2025-09-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000270', 'APP-2025-00274', '2025-09-18', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00187', 'APP-2025-00274', '2025-09-27', '2025-09-27', '2026-09-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00275', 'AP-00180', 'GF-00062', '2025-09-09', 'Renewal', 'Approved', '2025-10-01', 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00019', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00275', 1, 'Identity', 'REF-262254', '2025-09-09', 'Accepted', '2025-09-16', NULL),
('APP-2025-00275', 2, 'Registration', 'DOC-545258', '2025-09-14', 'Accepted', '2025-09-20', NULL),
('APP-2025-00275', 3, 'PriorPermit', 'PM-2025-00019', '2025-09-11', 'Accepted', '2025-09-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000271', 'APP-2025-00275', '2025-09-10', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00188', 'APP-2025-00275', '2025-10-05', '2025-10-05', '2026-10-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00276', 'AP-00057', 'GF-00059', '2025-09-10', 'New', 'Withdrawn', NULL, 'LC03', 'Mabini East', 'ACQ-39136-25', '2025-07-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00276', 1, 'Identity', 'REF-324758', '2025-09-10', 'Accepted', '2025-09-13', NULL),
('APP-2025-00276', 2, 'Registration', 'DOC-894912', '2025-09-10', 'Accepted', '2025-09-11', NULL),
('APP-2025-00276', 3, 'Acquisition', 'ACQ-39136-25', '2025-09-12', 'Accepted', '2025-09-13', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00277', 'AP-00040', 'GF-00099', '2025-09-11', 'New', 'Approved', '2025-09-17', 'LC07', 'Pulo Verde', 'ACQ-22452-25', '2025-08-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00277', 1, 'Identity', 'DOC-150857', '2025-09-11', 'Accepted', '2025-09-14', NULL),
('APP-2025-00277', 2, 'Registration', 'FILE-286951', '2025-09-14', 'Accepted', '2025-09-17', NULL),
('APP-2025-00277', 3, 'Acquisition', 'ACQ-22452-25', '2025-09-15', 'Accepted', '2025-09-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000272', 'APP-2025-00277', '2025-09-13', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00189', 'APP-2025-00277', '2025-09-17', '2025-09-17', '2026-09-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00278', 'AP-00125', 'GF-00109', '2025-09-11', 'Replacement', 'Approved', '2025-09-20', 'LC04', 'Bagong Silangan', NULL, NULL, NULL, NULL, '2025-08-24', 'IR-2025-2200');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00278', 1, 'Identity', 'FILE-101296', '2025-09-11', 'Accepted', '2025-09-13', NULL),
('APP-2025-00278', 2, 'Registration', 'FILE-892321', '2025-09-13', 'Accepted', '2025-09-15', NULL),
('APP-2025-00278', 3, 'Incident', 'IR-2025-2200', '2025-09-14', 'Accepted', '2025-09-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000273', 'APP-2025-00278', '2025-09-13', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00190', 'APP-2025-00278', '2025-09-24', '2025-09-24', '2026-09-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00279', 'AP-00174', 'GF-00131', '2025-09-15', 'New', 'Approved', '2025-09-18', 'LC03', 'Mabini East', 'ACQ-60848-25', '2025-08-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00279', 1, 'Identity', 'REF-991860', '2025-09-15', 'Accepted', '2025-09-17', NULL),
('APP-2025-00279', 2, 'Registration', 'DOC-951890', '2025-09-16', 'Accepted', '2025-09-18', NULL),
('APP-2025-00279', 3, 'Acquisition', 'ACQ-60848-25', '2025-09-18', 'Accepted', '2025-09-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000274', 'APP-2025-00279', '2025-09-18', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00280', 'AP-00118', 'GF-00074', '2025-09-15', 'Renewal', 'Approved', '2025-09-30', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00025', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00280', 1, 'Identity', 'REF-18081', '2025-09-15', 'Accepted', '2025-09-16', NULL),
('APP-2025-00280', 2, 'Registration', 'FILE-673257', '2025-09-16', 'Accepted', '2025-09-23', NULL),
('APP-2025-00280', 3, 'PriorPermit', 'PM-2025-00025', '2025-09-19', 'Accepted', '2025-09-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000275', 'APP-2025-00280', '2025-09-24', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00191', 'APP-2025-00280', '2025-10-01', '2025-10-01', '2026-09-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00281', 'AP-00128', 'GF-00100', '2025-09-16', 'New', 'Approved', '2025-09-20', 'LC01', 'Luntian Central', 'ACQ-35559-25', '2025-09-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00281', 1, 'Identity', 'DOC-625406', '2025-09-16', 'Accepted', '2025-09-20', NULL),
('APP-2025-00281', 2, 'Registration', 'DOC-712925', '2025-09-20', 'Accepted', '2025-09-20', NULL),
('APP-2025-00281', 3, 'Acquisition', 'ACQ-35559-25', '2025-09-20', 'Accepted', '2025-09-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000276', 'APP-2025-00281', '2025-09-20', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00192', 'APP-2025-00281', '2025-09-23', '2025-09-23', '2026-09-22', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00282', 'AP-00028', 'GF-00095', '2025-09-16', 'New', 'Approved', '2025-10-01', 'LC01', 'Luntian Central', 'ACQ-14864-25', '2025-05-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00282', 1, 'Identity', 'REF-55302', '2025-09-16', 'Accepted', '2025-09-22', NULL),
('APP-2025-00282', 2, 'Registration', 'DOC-231892', '2025-09-16', 'Accepted', '2025-09-18', NULL),
('APP-2025-00282', 3, 'Acquisition', 'ACQ-14864-25', '2025-09-17', 'Accepted', '2025-09-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000277', 'APP-2025-00282', '2025-09-20', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00193', 'APP-2025-00282', '2025-10-06', '2025-10-06', '2026-10-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00283', 'AP-00044', 'GF-00106', '2025-09-16', 'Renewal', 'Rejected', '2025-09-30', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00036', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00283', 1, 'Identity', 'REF-316450', '2025-09-16', 'Accepted', '2025-09-17', NULL),
('APP-2025-00283', 2, 'Registration', 'FILE-223341', '2025-09-20', 'Pending', NULL, NULL),
('APP-2025-00283', 3, 'PriorPermit', 'PM-2025-00036', '2025-09-20', 'Accepted', '2025-09-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000278', 'APP-2025-00283', '2025-09-21', 600, 'Online'),
('OR-2025-000279', 'APP-2025-00283', '2025-09-17', 100, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00284', 'AP-00067', 'GF-00101', '2025-09-16', 'Replacement', 'Approved', '2025-09-27', 'LC04', 'Bagong Silangan', NULL, NULL, NULL, NULL, '2025-08-28', 'IR-2025-4852');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00284', 1, 'Identity', 'REF-582502', '2025-09-16', 'Accepted', '2025-09-20', NULL),
('APP-2025-00284', 2, 'Registration', 'DOC-93228', '2025-09-18', 'Accepted', '2025-09-22', NULL),
('APP-2025-00284', 3, 'Incident', 'IR-2025-4852', '2025-09-21', 'Accepted', '2025-09-23', NULL),
('APP-2025-00284', 4, 'Other', 'REF-304941', '2025-09-20', 'Accepted', '2025-09-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000280', 'APP-2025-00284', '2025-09-22', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00194', 'APP-2025-00284', '2025-10-01', '2025-10-01', '2026-09-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00285', 'AP-00098', 'GF-00085', '2025-09-17', 'New', 'Approved', '2025-10-01', 'LC02', 'San Isidro Heights', 'ACQ-21694-25', '2025-08-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00285', 1, 'Identity', 'REF-626997', '2025-09-17', 'Accepted', '2025-09-23', NULL),
('APP-2025-00285', 2, 'Registration', 'FILE-597782', '2025-09-21', 'Accepted', '2025-09-22', NULL),
('APP-2025-00285', 3, 'Acquisition', 'ACQ-21694-25', '2025-09-19', 'Accepted', '2025-09-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000281', 'APP-2025-00285', '2025-09-19', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00195', 'APP-2025-00285', '2025-10-03', '2025-10-03', '2026-10-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00286', 'AP-00125', 'GF-00147', '2025-09-17', 'Renewal', 'Approved', '2025-09-25', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00063', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00286', 1, 'Identity', 'FILE-480818', '2025-09-17', 'Accepted', '2025-09-22', NULL),
('APP-2025-00286', 2, 'Registration', 'REF-34137', '2025-09-20', 'Accepted', '2025-09-24', NULL),
('APP-2025-00286', 3, 'PriorPermit', 'PM-2025-00063', '2025-09-19', 'Accepted', '2025-09-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000282', 'APP-2025-00286', '2025-09-17', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00196', 'APP-2025-00286', '2025-09-27', '2025-09-27', '2026-09-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00287', 'AP-00167', 'GF-00056', '2025-09-18', 'Replacement', 'Approved', '2025-10-09', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2025-08-21', 'IR-2025-8327');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00287', 1, 'Identity', 'REF-463559', '2025-09-18', 'Accepted', '2025-09-25', NULL),
('APP-2025-00287', 2, 'Registration', 'FILE-153945', '2025-09-18', 'Accepted', '2025-09-25', NULL),
('APP-2025-00287', 3, 'Incident', 'IR-2025-8327', '2025-09-23', 'Accepted', '2025-09-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000283', 'APP-2025-00287', '2025-09-24', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00197', 'APP-2025-00287', '2025-10-11', '2025-10-11', '2026-10-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00288', 'AP-00035', 'GF-00097', '2025-09-19', 'New', 'Approved', '2025-09-24', 'LC02', 'San Isidro Heights', 'ACQ-39971-25', '2025-06-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00288', 1, 'Identity', 'FILE-225045', '2025-09-19', 'Accepted', '2025-09-24', NULL),
('APP-2025-00288', 2, 'Registration', 'DOC-270318', '2025-09-19', 'Accepted', '2025-09-24', NULL),
('APP-2025-00288', 3, 'Acquisition', 'ACQ-39971-25', '2025-09-22', 'Accepted', '2025-09-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000284', 'APP-2025-00288', '2025-09-23', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00198', 'APP-2025-00288', '2025-09-25', '2025-09-25', '2026-09-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00289', 'AP-00049', 'GF-00023', '2025-09-19', 'New', 'Approved', '2025-10-07', 'LC04', 'Bagong Silangan', 'ACQ-49322-25', '2025-07-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00289', 1, 'Identity', 'DOC-75297', '2025-09-19', 'Accepted', '2025-09-22', NULL),
('APP-2025-00289', 2, 'Registration', 'DOC-191781', '2025-09-23', 'Accepted', '2025-09-24', NULL),
('APP-2025-00289', 3, 'Acquisition', 'ACQ-49322-25', '2025-09-24', 'Accepted', '2025-09-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000285', 'APP-2025-00289', '2025-10-01', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00199', 'APP-2025-00289', '2025-10-07', '2025-10-07', '2026-10-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00290', 'AP-00154', 'GF-00092', '2025-09-19', 'Renewal', 'Approved', '2025-09-28', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2024-00002', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00290', 1, 'Identity', 'FILE-41868', '2025-09-19', 'Accepted', '2025-09-25', NULL),
('APP-2025-00290', 2, 'Registration', 'DOC-643632', '2025-09-24', 'Accepted', '2025-09-25', NULL),
('APP-2025-00290', 3, 'PriorPermit', 'PM-2024-00002', '2025-09-22', 'Accepted', '2025-09-28', NULL),
('APP-2025-00290', 4, 'Other', 'REF-996441', '2025-09-20', 'Accepted', '2025-09-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000286', 'APP-2025-00290', '2025-09-22', 350, 'BankTransfer'),
('OR-2025-000287', 'APP-2025-00290', '2025-09-22', 150, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00200', 'APP-2025-00290', '2025-09-29', '2025-09-29', '2026-09-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00291', 'AP-00163', 'GF-00074', '2025-09-21', 'New', 'Approved', '2025-09-24', 'LC01', 'Luntian Central', 'ACQ-52770-25', '2025-05-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00291', 1, 'Identity', 'REF-754206', '2025-09-21', 'Accepted', '2025-09-22', NULL),
('APP-2025-00291', 2, 'Registration', 'DOC-662583', '2025-09-21', 'Accepted', '2025-09-24', NULL),
('APP-2025-00291', 3, 'Acquisition', 'ACQ-52770-25', '2025-09-24', 'Accepted', '2025-09-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000288', 'APP-2025-00291', '2025-09-21', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00201', 'APP-2025-00291', '2025-09-24', '2025-09-24', '2026-09-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00292', 'AP-00118', 'GF-00018', '2025-09-21', 'New', 'Approved', '2025-09-30', 'LC01', 'Luntian Central', 'ACQ-54326-25', '2025-08-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00292', 1, 'Identity', 'REF-223543', '2025-09-21', 'Accepted', '2025-09-27', NULL),
('APP-2025-00292', 2, 'Registration', 'FILE-684953', '2025-09-21', 'Accepted', '2025-09-24', NULL),
('APP-2025-00292', 3, 'Acquisition', 'ACQ-54326-25', '2025-09-25', 'Accepted', '2025-09-28', NULL),
('APP-2025-00292', 4, 'Other', 'REF-975012', '2025-09-23', 'Accepted', '2025-09-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000289', 'APP-2025-00292', '2025-09-24', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00202', 'APP-2025-00292', '2025-10-04', '2025-10-04', '2026-10-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00293', 'AP-00039', 'GF-00105', '2025-09-21', 'New', 'Approved', '2025-09-26', 'LC01', 'Luntian Central', 'ACQ-54892-25', '2025-08-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00293', 1, 'Identity', 'FILE-790970', '2025-09-21', 'Accepted', '2025-09-26', NULL),
('APP-2025-00293', 2, 'Registration', 'DOC-375987', '2025-09-24', 'Accepted', '2025-09-26', NULL),
('APP-2025-00293', 3, 'Acquisition', 'ACQ-54892-25', '2025-09-24', 'Accepted', '2025-09-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000290', 'APP-2025-00293', '2025-09-22', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00203', 'APP-2025-00293', '2025-09-26', '2025-09-26', '2026-09-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00294', 'AP-00185', 'GF-00005', '2025-09-21', 'Renewal', 'UnderReview', NULL, 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00041', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00294', 1, 'Identity', 'DOC-616363', '2025-09-21', 'Pending', NULL, NULL),
('APP-2025-00294', 2, 'Registration', 'REF-80929', '2025-09-24', 'Pending', NULL, NULL),
('APP-2025-00294', 3, 'PriorPermit', 'PM-2025-00041', '2025-09-25', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00295', 'AP-00172', 'GF-00099', '2025-09-23', 'New', 'Approved', '2025-10-08', 'LC06', 'Maligaya', 'ACQ-67383-25', '2025-07-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00295', 1, 'Identity', 'REF-565191', '2025-09-23', 'Accepted', '2025-09-24', NULL),
('APP-2025-00295', 2, 'Registration', 'REF-343702', '2025-09-27', 'Accepted', '2025-10-01', NULL),
('APP-2025-00295', 3, 'Acquisition', 'ACQ-67383-25', '2025-09-23', 'Accepted', '2025-09-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000291', 'APP-2025-00295', '2025-09-23', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00204', 'APP-2025-00295', '2025-10-08', '2025-10-08', '2026-10-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00296', 'AP-00117', 'GF-00029', '2025-09-25', 'New', 'Approved', '2025-09-29', 'LC04', 'Bagong Silangan', 'ACQ-31534-25', '2025-06-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00296', 1, 'Identity', 'FILE-248417', '2025-09-25', 'Accepted', '2025-09-29', NULL),
('APP-2025-00296', 2, 'Registration', 'FILE-531349', '2025-09-28', 'Accepted', '2025-09-29', NULL),
('APP-2025-00296', 3, 'Acquisition', 'ACQ-31534-25', '2025-09-27', 'Accepted', '2025-09-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000292', 'APP-2025-00296', '2025-09-29', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00205', 'APP-2025-00296', '2025-10-02', '2025-10-02', '2026-10-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00297', 'AP-00025', 'GF-00089', '2025-09-25', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-45976-25', '2025-08-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00297', 1, 'Identity', 'DOC-129338', '2025-09-25', 'NeedsCorrection', '2025-09-30', 'The date on the document needs clarification.'),
('APP-2025-00297', 2, 'Registration', 'DOC-186115', '2025-09-29', 'NeedsCorrection', '2025-10-05', 'A clearer copy of the reference portion is requested.'),
('APP-2025-00297', 3, 'Acquisition', 'ACQ-45976-25', '2025-09-30', 'Accepted', '2025-10-02', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00298', 'AP-00090', 'GF-00089', '2025-09-26', 'New', 'Approved', '2025-10-15', 'LC03', 'Mabini East', 'ACQ-78752-25', '2025-08-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00298', 1, 'Identity', 'REF-450189', '2025-09-26', 'Accepted', '2025-10-01', NULL),
('APP-2025-00298', 2, 'Registration', 'FILE-412218', '2025-09-26', 'Accepted', '2025-09-28', NULL),
('APP-2025-00298', 3, 'Acquisition', 'ACQ-78752-25', '2025-09-27', 'Accepted', '2025-09-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000293', 'APP-2025-00298', '2025-10-02', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00206', 'APP-2025-00298', '2025-10-19', '2025-10-19', '2026-10-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00299', 'AP-00109', 'GF-00048', '2025-09-28', 'New', 'Submitted', NULL, 'LC03', 'Mabini East', 'ACQ-50483-25', '2025-09-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00299', 1, 'Identity', 'REF-455557', '2025-09-28', 'Pending', NULL, NULL),
('APP-2025-00299', 2, 'Registration', 'DOC-867800', '2025-09-30', 'Pending', NULL, NULL),
('APP-2025-00299', 3, 'Acquisition', 'ACQ-50483-25', '2025-09-30', 'Pending', NULL, NULL),
('APP-2025-00299', 4, 'Other', 'REF-333745', '2025-10-02', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000294', 'APP-2025-00299', '2025-09-28', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00300', 'AP-00049', 'GF-00113', '2025-09-28', 'New', 'Approved', '2025-11-02', 'LC04', 'Bagong Silangan', 'ACQ-15603-25', '2025-06-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00300', 1, 'Identity', 'FILE-10988', '2025-09-28', 'Accepted', '2025-10-04', NULL),
('APP-2025-00300', 2, 'Registration', 'FILE-314548', '2025-10-03', 'Accepted', '2025-10-04', NULL),
('APP-2025-00300', 3, 'Acquisition', 'ACQ-15603-25', '2025-09-29', 'Accepted', '2025-10-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000295', 'APP-2025-00300', '2025-10-10', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00207', 'APP-2025-00300', '2025-11-04', '2025-11-04', '2026-11-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00301', 'AP-00018', 'GF-00033', '2025-09-28', 'New', 'Approved', '2025-10-10', 'LC05', 'Santa Elena', 'ACQ-43253-25', '2025-07-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00301', 1, 'Identity', 'FILE-304105', '2025-09-28', 'Accepted', '2025-10-02', NULL),
('APP-2025-00301', 2, 'Registration', 'FILE-157767', '2025-09-29', 'Accepted', '2025-10-04', NULL),
('APP-2025-00301', 3, 'Acquisition', 'ACQ-43253-25', '2025-09-28', 'Accepted', '2025-09-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000296', 'APP-2025-00301', '2025-10-02', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00208', 'APP-2025-00301', '2025-10-15', '2025-10-15', '2026-10-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00302', 'AP-00161', 'GF-00005', '2025-09-28', 'Renewal', 'Approved', '2025-10-04', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00059', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00302', 1, 'Identity', 'REF-684551', '2025-09-28', 'Accepted', '2025-10-03', NULL),
('APP-2025-00302', 2, 'Registration', 'DOC-770428', '2025-10-02', 'Accepted', '2025-10-04', NULL),
('APP-2025-00302', 3, 'PriorPermit', 'PM-2025-00059', '2025-09-29', 'Accepted', '2025-09-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000297', 'APP-2025-00302', '2025-09-30', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00209', 'APP-2025-00302', '2025-10-09', '2025-10-09', '2026-10-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00303', 'AP-00051', 'GF-00131', '2025-09-28', 'Renewal', 'Approved', '2025-10-04', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00044', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00303', 1, 'Identity', 'DOC-60387', '2025-09-28', 'Accepted', '2025-10-02', NULL),
('APP-2025-00303', 2, 'Registration', 'FILE-711698', '2025-09-29', 'Accepted', '2025-10-04', NULL),
('APP-2025-00303', 3, 'PriorPermit', 'PM-2025-00044', '2025-09-30', 'Accepted', '2025-10-04', NULL),
('APP-2025-00303', 4, 'Other', 'FILE-635808', '2025-10-01', 'Accepted', '2025-10-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000298', 'APP-2025-00303', '2025-10-02', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00210', 'APP-2025-00303', '2025-10-04', '2025-10-04', '2026-10-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00304', 'AP-00045', 'GF-00143', '2025-09-30', 'New', 'Approved', '2025-10-10', 'LC06', 'Maligaya', 'ACQ-61533-25', '2025-09-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00304', 1, 'Identity', 'FILE-588250', '2025-09-30', 'Accepted', '2025-10-06', NULL),
('APP-2025-00304', 2, 'Registration', 'FILE-333341', '2025-10-02', 'Accepted', '2025-10-06', NULL),
('APP-2025-00304', 3, 'Acquisition', 'ACQ-61533-25', '2025-10-05', 'Accepted', '2025-10-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000299', 'APP-2025-00304', '2025-10-06', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00211', 'APP-2025-00304', '2025-10-15', '2025-10-15', '2026-10-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00305', 'AP-00118', 'GF-00084', '2025-10-04', 'New', 'Approved', '2025-10-24', 'LC01', 'Luntian Central', 'ACQ-61540-25', '2025-06-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00305', 1, 'Identity', 'REF-189706', '2025-10-04', 'Accepted', '2025-10-05', NULL),
('APP-2025-00305', 2, 'Registration', 'REF-336804', '2025-10-09', 'Accepted', '2025-10-14', NULL),
('APP-2025-00305', 3, 'Acquisition', 'ACQ-61540-25', '2025-10-06', 'Accepted', '2025-10-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000300', 'APP-2025-00305', '2025-10-05', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00306', 'AP-00001', 'GF-00055', '2025-10-05', 'New', 'Approved', '2025-10-12', 'LC01', 'Luntian Central', 'ACQ-87984-25', '2025-08-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00306', 1, 'Identity', 'FILE-582570', '2025-10-05', 'Accepted', '2025-10-10', NULL),
('APP-2025-00306', 2, 'Registration', 'DOC-259402', '2025-10-09', 'Accepted', '2025-10-12', NULL),
('APP-2025-00306', 3, 'Acquisition', 'ACQ-87984-25', '2025-10-08', 'Accepted', '2025-10-10', NULL),
('APP-2025-00306', 4, 'Other', 'FILE-688398', '2025-10-08', 'Accepted', '2025-10-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000301', 'APP-2025-00306', '2025-10-07', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00212', 'APP-2025-00306', '2025-10-14', '2025-10-14', '2026-10-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00307', 'AP-00129', 'GF-00119', '2025-10-06', 'New', 'Approved', '2025-10-10', 'LC01', 'Luntian Central', 'ACQ-46171-25', '2025-06-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00307', 1, 'Identity', 'REF-859854', '2025-10-06', 'Accepted', '2025-10-08', NULL),
('APP-2025-00307', 2, 'Registration', 'REF-637516', '2025-10-06', 'Accepted', '2025-10-10', NULL),
('APP-2025-00307', 3, 'Acquisition', 'ACQ-46171-25', '2025-10-07', 'Accepted', '2025-10-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000302', 'APP-2025-00307', '2025-10-07', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00213', 'APP-2025-00307', '2025-10-15', '2025-10-15', '2026-10-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00308', 'AP-00028', 'GF-00048', '2025-10-06', 'New', 'Approved', '2025-10-13', 'LC01', 'Luntian Central', 'ACQ-49368-25', '2025-06-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00308', 1, 'Identity', 'REF-365269', '2025-10-06', 'Accepted', '2025-10-09', NULL),
('APP-2025-00308', 2, 'Registration', 'DOC-669898', '2025-10-11', 'Accepted', '2025-10-13', NULL),
('APP-2025-00308', 3, 'Acquisition', 'ACQ-49368-25', '2025-10-11', 'Accepted', '2025-10-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000303', 'APP-2025-00308', '2025-10-13', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00214', 'APP-2025-00308', '2025-10-17', '2025-10-17', '2026-10-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00309', 'AP-00186', 'GF-00087', '2025-10-06', 'New', 'Approved', '2025-10-20', 'LC04', 'Bagong Silangan', 'ACQ-52793-25', '2025-07-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00309', 1, 'Identity', 'DOC-277686', '2025-10-06', 'Accepted', '2025-10-11', NULL),
('APP-2025-00309', 2, 'Registration', 'REF-143543', '2025-10-10', 'Accepted', '2025-10-11', NULL),
('APP-2025-00309', 3, 'Acquisition', 'ACQ-52793-25', '2025-10-07', 'Accepted', '2025-10-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000304', 'APP-2025-00309', '2025-10-10', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00215', 'APP-2025-00309', '2025-10-21', '2025-10-21', '2026-10-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00310', 'AP-00006', 'GF-00042', '2025-10-06', 'Renewal', 'Approved', '2025-10-14', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00030', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00310', 1, 'Identity', 'DOC-635199', '2025-10-06', 'Accepted', '2025-10-11', NULL),
('APP-2025-00310', 2, 'Registration', 'FILE-589196', '2025-10-10', 'Accepted', '2025-10-11', NULL),
('APP-2025-00310', 3, 'PriorPermit', 'PM-2025-00030', '2025-10-06', 'Accepted', '2025-10-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000305', 'APP-2025-00310', '2025-10-14', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00216', 'APP-2025-00310', '2025-10-14', '2025-10-14', '2026-10-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00311', 'AP-00010', 'GF-00141', '2025-10-08', 'New', 'Approved', '2025-10-12', 'LC07', 'Pulo Verde', 'ACQ-24093-25', '2025-08-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00311', 1, 'Identity', 'REF-765636', '2025-10-08', 'Accepted', '2025-10-09', NULL),
('APP-2025-00311', 2, 'Registration', 'REF-96493', '2025-10-12', 'Accepted', '2025-10-12', NULL),
('APP-2025-00311', 3, 'Acquisition', 'ACQ-24093-25', '2025-10-12', 'Accepted', '2025-10-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000306', 'APP-2025-00311', '2025-10-10', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00217', 'APP-2025-00311', '2025-10-13', '2025-10-13', '2026-10-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00312', 'AP-00166', 'GF-00021', '2025-10-09', 'New', 'Approved', '2025-11-09', 'LC05', 'Santa Elena', 'ACQ-66899-25', '2025-09-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00312', 1, 'Identity', 'FILE-419664', '2025-10-09', 'Accepted', '2025-10-13', NULL),
('APP-2025-00312', 2, 'Registration', 'REF-310714', '2025-10-13', 'Accepted', '2025-10-15', NULL),
('APP-2025-00312', 3, 'Acquisition', 'ACQ-66899-25', '2025-10-13', 'Accepted', '2025-10-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000307', 'APP-2025-00312', '2025-10-16', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00218', 'APP-2025-00312', '2025-11-12', '2025-11-12', '2026-11-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00313', 'AP-00164', 'GF-00107', '2025-10-09', 'New', 'Approved', '2025-10-22', 'LC03', 'Mabini East', 'ACQ-27974-25', '2025-06-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00313', 1, 'Identity', 'FILE-784207', '2025-10-09', 'Accepted', '2025-10-10', NULL),
('APP-2025-00313', 2, 'Registration', 'FILE-923990', '2025-10-12', 'Accepted', '2025-10-19', NULL),
('APP-2025-00313', 3, 'Acquisition', 'ACQ-27974-25', '2025-10-13', 'Accepted', '2025-10-15', NULL),
('APP-2025-00313', 4, 'Other', 'FILE-501563', '2025-10-13', 'Accepted', '2025-10-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000308', 'APP-2025-00313', '2025-10-15', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00219', 'APP-2025-00313', '2025-10-25', '2025-10-25', '2026-10-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00314', 'AP-00089', 'GF-00117', '2025-10-11', 'New', 'Approved', '2025-10-19', 'LC01', 'Luntian Central', 'ACQ-89038-25', '2025-08-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00314', 1, 'Identity', 'REF-622678', '2025-10-11', 'Accepted', '2025-10-12', NULL),
('APP-2025-00314', 2, 'Registration', 'REF-99005', '2025-10-11', 'Accepted', '2025-10-17', NULL),
('APP-2025-00314', 3, 'Acquisition', 'ACQ-89038-25', '2025-10-16', 'Accepted', '2025-10-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000309', 'APP-2025-00314', '2025-10-14', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00220', 'APP-2025-00314', '2025-10-20', '2025-10-20', '2026-10-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00315', 'AP-00046', 'GF-00007', '2025-10-12', 'Renewal', 'Approved', '2025-10-17', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00081', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00315', 1, 'Identity', 'DOC-200946', '2025-10-12', 'Accepted', '2025-10-15', NULL),
('APP-2025-00315', 2, 'Registration', 'REF-971398', '2025-10-14', 'Accepted', '2025-10-17', NULL),
('APP-2025-00315', 3, 'PriorPermit', 'PM-2025-00081', '2025-10-13', 'Accepted', '2025-10-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000310', 'APP-2025-00315', '2025-10-17', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00221', 'APP-2025-00315', '2025-10-20', '2025-10-20', '2026-10-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00316', 'AP-00094', 'GF-00081', '2025-10-14', 'New', 'Approved', '2025-11-04', 'LC03', 'Mabini East', 'ACQ-30932-25', '2025-07-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00316', 1, 'Identity', 'DOC-932806', '2025-10-14', 'Accepted', '2025-10-17', NULL),
('APP-2025-00316', 2, 'Registration', 'REF-68298', '2025-10-15', 'Accepted', '2025-10-21', NULL),
('APP-2025-00316', 3, 'Acquisition', 'ACQ-30932-25', '2025-10-14', 'Accepted', '2025-10-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000311', 'APP-2025-00316', '2025-10-22', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00222', 'APP-2025-00316', '2025-11-07', '2025-11-07', '2026-11-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00317', 'AP-00019', 'GF-00161', '2025-10-15', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-88088-25', '2025-06-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00317', 1, 'Identity', 'REF-148608', '2025-10-15', 'Accepted', '2025-10-16', NULL),
('APP-2025-00317', 2, 'Registration', 'DOC-745324', '2025-10-19', 'Accepted', '2025-10-23', NULL),
('APP-2025-00317', 3, 'Acquisition', 'ACQ-88088-25', '2025-10-20', 'Accepted', '2025-10-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000312', 'APP-2025-00317', '2025-10-25', 450, 'Online'),
('OR-2025-000313', 'APP-2025-00317', '2025-10-27', 150, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00318', 'AP-00067', 'GF-00101', '2025-10-17', 'Renewal', 'Approved', '2025-11-11', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2024-00005', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00318', 1, 'Identity', 'REF-153147', '2025-10-17', 'Accepted', '2025-10-24', NULL),
('APP-2025-00318', 2, 'Registration', 'FILE-534543', '2025-10-18', 'Accepted', '2025-10-25', NULL),
('APP-2025-00318', 3, 'PriorPermit', 'PM-2024-00005', '2025-10-19', 'Accepted', '2025-10-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000314', 'APP-2025-00318', '2025-10-17', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00223', 'APP-2025-00318', '2025-11-15', '2025-11-15', '2026-11-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00319', 'AP-00119', 'GF-00152', '2025-10-19', 'New', 'Approved', '2025-12-15', 'LC01', 'Luntian Central', 'ACQ-17683-25', '2025-06-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00319', 1, 'Identity', 'DOC-814640', '2025-10-19', 'Accepted', '2025-10-20', NULL),
('APP-2025-00319', 2, 'Registration', 'DOC-983173', '2025-10-22', 'Accepted', '2025-10-23', NULL),
('APP-2025-00319', 3, 'Acquisition', 'ACQ-17683-25', '2025-10-21', 'Accepted', '2025-10-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000315', 'APP-2025-00319', '2025-10-28', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00224', 'APP-2025-00319', '2025-12-20', '2025-12-20', '2026-12-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00320', 'AP-00114', 'GF-00131', '2025-10-19', 'New', 'Approved', '2025-11-08', 'LC01', 'Luntian Central', 'ACQ-11265-25', '2025-07-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00320', 1, 'Identity', 'FILE-213963', '2025-10-19', 'Accepted', '2025-10-20', NULL),
('APP-2025-00320', 2, 'Registration', 'DOC-888441', '2025-10-19', 'Accepted', '2025-10-24', NULL),
('APP-2025-00320', 3, 'Acquisition', 'ACQ-11265-25', '2025-10-23', 'Accepted', '2025-10-24', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00225', 'APP-2025-00320', '2025-11-09', '2025-11-09', '2026-11-08', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00321', 'AP-00099', 'GF-00141', '2025-10-20', 'New', 'Approved', '2025-10-27', 'LC03', 'Mabini East', 'ACQ-32865-25', '2025-08-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00321', 1, 'Identity', 'DOC-415955', '2025-10-20', 'Accepted', '2025-10-27', NULL),
('APP-2025-00321', 2, 'Registration', 'REF-717928', '2025-10-25', 'Accepted', '2025-10-26', NULL),
('APP-2025-00321', 3, 'Acquisition', 'ACQ-32865-25', '2025-10-24', 'Accepted', '2025-10-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000316', 'APP-2025-00321', '2025-10-27', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00226', 'APP-2025-00321', '2025-10-28', '2025-10-28', '2026-10-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00322', 'AP-00048', 'GF-00013', '2025-10-20', 'Renewal', 'Approved', '2025-11-09', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00079', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00322', 1, 'Identity', 'FILE-547694', '2025-10-20', 'Accepted', '2025-10-22', NULL),
('APP-2025-00322', 2, 'Registration', 'FILE-253811', '2025-10-23', 'Accepted', '2025-10-28', NULL),
('APP-2025-00322', 3, 'PriorPermit', 'PM-2025-00079', '2025-10-21', 'Accepted', '2025-10-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000317', 'APP-2025-00322', '2025-10-26', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00227', 'APP-2025-00322', '2025-11-13', '2025-11-13', '2026-11-12', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00323', 'AP-00053', 'GF-00017', '2025-10-23', 'New', 'UnderReview', NULL, 'LC07', 'Pulo Verde', 'ACQ-34098-25', '2025-09-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00323', 1, 'Identity', 'FILE-301395', '2025-10-23', 'Accepted', '2025-10-29', NULL),
('APP-2025-00323', 2, 'Registration', 'DOC-844791', '2025-10-25', 'Accepted', '2025-11-01', NULL),
('APP-2025-00323', 3, 'Acquisition', 'ACQ-34098-25', '2025-10-28', 'NeedsCorrection', '2025-11-01', 'A clearer copy of the reference portion is requested.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000318', 'APP-2025-00323', '2025-10-24', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00324', 'AP-00161', 'GF-00055', '2025-10-23', 'New', 'Withdrawn', NULL, 'LC01', 'Luntian Central', 'ACQ-16925-25', '2025-09-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00324', 1, 'Identity', 'REF-878790', '2025-10-23', 'NeedsCorrection', '2025-10-24', 'Please provide the missing page of the supporting document.'),
('APP-2025-00324', 2, 'Registration', 'DOC-794149', '2025-10-25', 'Pending', NULL, NULL),
('APP-2025-00324', 3, 'Acquisition', 'ACQ-16925-25', '2025-10-26', 'Accepted', '2025-11-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000319', 'APP-2025-00324', '2025-10-29', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00325', 'AP-00186', 'GF-00078', '2025-10-24', 'New', 'Approved', '2025-11-03', 'LC04', 'Bagong Silangan', 'ACQ-76774-25', '2025-08-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00325', 1, 'Identity', 'REF-51176', '2025-10-24', 'Accepted', '2025-10-26', NULL),
('APP-2025-00325', 2, 'Registration', 'REF-824691', '2025-10-29', 'Accepted', '2025-11-03', NULL),
('APP-2025-00325', 3, 'Acquisition', 'ACQ-76774-25', '2025-10-24', 'Accepted', '2025-10-26', NULL),
('APP-2025-00325', 4, 'Other', 'DOC-876362', '2025-10-28', 'Accepted', '2025-10-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000320', 'APP-2025-00325', '2025-11-03', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00228', 'APP-2025-00325', '2025-11-08', '2025-11-08', '2026-11-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00326', 'AP-00069', 'GF-00139', '2025-10-24', 'Renewal', 'Approved', '2025-11-07', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00073', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00326', 1, 'Identity', 'DOC-861536', '2025-10-24', 'Accepted', '2025-10-28', NULL),
('APP-2025-00326', 2, 'Registration', 'REF-719687', '2025-10-26', 'Accepted', '2025-10-30', NULL),
('APP-2025-00326', 3, 'PriorPermit', 'PM-2025-00073', '2025-10-28', 'Accepted', '2025-10-29', NULL),
('APP-2025-00326', 4, 'Other', 'FILE-478808', '2025-10-27', 'Accepted', '2025-11-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000321', 'APP-2025-00326', '2025-11-03', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00229', 'APP-2025-00326', '2025-11-09', '2025-11-09', '2026-11-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00327', 'AP-00176', 'GF-00146', '2025-10-24', 'Replacement', 'Approved', '2025-12-02', 'LC04', 'Bagong Silangan', NULL, NULL, NULL, NULL, '2025-10-01', 'IR-2025-4149');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00327', 1, 'Identity', 'FILE-340312', '2025-10-24', 'Accepted', '2025-10-30', NULL),
('APP-2025-00327', 2, 'Registration', 'FILE-318946', '2025-10-27', 'Accepted', '2025-11-01', NULL),
('APP-2025-00327', 3, 'Incident', 'IR-2025-4149', '2025-10-25', 'Accepted', '2025-10-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000322', 'APP-2025-00327', '2025-11-01', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00230', 'APP-2025-00327', '2025-12-03', '2025-12-03', '2026-12-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00328', 'AP-00168', 'GF-00149', '2025-10-26', 'New', 'Approved', '2025-11-12', 'LC01', 'Luntian Central', 'ACQ-41440-25', '2025-09-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00328', 1, 'Identity', 'DOC-566884', '2025-10-26', 'Accepted', '2025-10-28', NULL),
('APP-2025-00328', 2, 'Registration', 'REF-732383', '2025-10-29', 'Accepted', '2025-11-03', NULL),
('APP-2025-00328', 3, 'Acquisition', 'ACQ-41440-25', '2025-10-27', 'Accepted', '2025-10-29', NULL),
('APP-2025-00328', 4, 'Other', 'REF-808444', '2025-10-30', 'Accepted', '2025-11-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000323', 'APP-2025-00328', '2025-11-07', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00231', 'APP-2025-00328', '2025-11-12', '2025-11-12', '2026-11-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00329', 'AP-00108', 'GF-00011', '2025-10-26', 'New', 'Approved', '2025-11-13', 'LC02', 'San Isidro Heights', 'ACQ-40713-25', '2025-09-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00329', 1, 'Identity', 'DOC-252025', '2025-10-26', 'Accepted', '2025-10-29', NULL),
('APP-2025-00329', 2, 'Registration', 'REF-440581', '2025-10-27', 'Accepted', '2025-10-29', NULL),
('APP-2025-00329', 3, 'Acquisition', 'ACQ-40713-25', '2025-10-30', 'Accepted', '2025-11-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000324', 'APP-2025-00329', '2025-10-30', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00330', 'AP-00070', 'GF-00049', '2025-10-29', 'New', 'Approved', '2025-11-15', 'LC07', 'Pulo Verde', 'ACQ-71609-25', '2025-07-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00330', 1, 'Identity', 'REF-856904', '2025-10-29', 'Accepted', '2025-11-05', NULL),
('APP-2025-00330', 2, 'Registration', 'DOC-957006', '2025-10-30', 'Accepted', '2025-10-31', NULL),
('APP-2025-00330', 3, 'Acquisition', 'ACQ-71609-25', '2025-11-02', 'Accepted', '2025-11-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000325', 'APP-2025-00330', '2025-11-06', 450, 'Cash'),
('OR-2025-000326', 'APP-2025-00330', '2025-11-07', 100, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00331', 'AP-00165', 'GF-00121', '2025-10-29', 'Renewal', 'Approved', '2025-11-13', 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00096', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00331', 1, 'Identity', 'REF-831758', '2025-10-29', 'Accepted', '2025-11-04', NULL),
('APP-2025-00331', 2, 'Registration', 'DOC-778495', '2025-11-01', 'Accepted', '2025-11-05', NULL),
('APP-2025-00331', 3, 'PriorPermit', 'PM-2025-00096', '2025-10-30', 'Accepted', '2025-11-02', NULL),
('APP-2025-00331', 4, 'Other', 'DOC-553314', '2025-10-29', 'Accepted', '2025-10-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000327', 'APP-2025-00331', '2025-11-09', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00232', 'APP-2025-00331', '2025-11-17', '2025-11-17', '2026-11-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00332', 'AP-00120', 'GF-00159', '2025-10-30', 'New', 'Approved', '2025-11-20', 'LC02', 'San Isidro Heights', 'ACQ-76902-25', '2025-08-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00332', 1, 'Identity', 'FILE-943198', '2025-10-30', 'Accepted', '2025-10-31', NULL),
('APP-2025-00332', 2, 'Registration', 'FILE-625719', '2025-11-04', 'Accepted', '2025-11-10', NULL),
('APP-2025-00332', 3, 'Acquisition', 'ACQ-76902-25', '2025-11-01', 'Accepted', '2025-11-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000328', 'APP-2025-00332', '2025-11-07', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00233', 'APP-2025-00332', '2025-11-25', '2025-11-25', '2026-11-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00333', 'AP-00178', 'GF-00040', '2025-10-31', 'New', 'Submitted', NULL, 'LC02', 'San Isidro Heights', 'ACQ-68927-25', '2025-10-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00333', 1, 'Identity', 'DOC-693681', '2025-10-31', 'Pending', NULL, NULL),
('APP-2025-00333', 2, 'Registration', 'DOC-311974', '2025-11-04', 'Pending', NULL, NULL),
('APP-2025-00333', 3, 'Other', 'REF-359789', '2025-10-31', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000329', 'APP-2025-00333', '2025-11-10', 1200, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00334', 'AP-00024', 'GF-00088', '2025-11-01', 'Replacement', 'Approved', '2025-11-12', 'LC07', 'Pulo Verde', NULL, NULL, NULL, NULL, '2025-10-11', 'IR-2025-1141');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00334', 1, 'Identity', 'FILE-180856', '2025-11-01', 'Accepted', '2025-11-07', NULL),
('APP-2025-00334', 2, 'Registration', 'FILE-515294', '2025-11-03', 'Accepted', '2025-11-10', NULL),
('APP-2025-00334', 3, 'Incident', 'IR-2025-1141', '2025-11-02', 'Accepted', '2025-11-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000330', 'APP-2025-00334', '2025-11-06', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00234', 'APP-2025-00334', '2025-11-17', '2025-11-17', '2026-11-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00335', 'AP-00046', 'GF-00137', '2025-11-02', 'Renewal', 'Approved', '2025-11-13', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00072', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00335', 1, 'Identity', 'REF-797627', '2025-11-02', 'Accepted', '2025-11-06', NULL),
('APP-2025-00335', 2, 'Registration', 'FILE-300216', '2025-11-06', 'Accepted', '2025-11-13', NULL),
('APP-2025-00335', 3, 'PriorPermit', 'PM-2025-00072', '2025-11-03', 'Accepted', '2025-11-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000331', 'APP-2025-00335', '2025-11-04', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00235', 'APP-2025-00335', '2025-11-15', '2025-11-15', '2026-11-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00336', 'AP-00185', 'GF-00100', '2025-11-03', 'New', 'Approved', '2025-11-20', 'LC03', 'Mabini East', 'ACQ-75901-25', '2025-07-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00336', 1, 'Identity', 'DOC-70095', '2025-11-03', 'Accepted', '2025-11-04', NULL),
('APP-2025-00336', 2, 'Registration', 'REF-243731', '2025-11-03', 'Accepted', '2025-11-06', NULL),
('APP-2025-00336', 3, 'Acquisition', 'ACQ-75901-25', '2025-11-05', 'Accepted', '2025-11-10', NULL),
('APP-2025-00336', 4, 'Other', 'FILE-504855', '2025-11-07', 'Accepted', '2025-11-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000332', 'APP-2025-00336', '2025-11-15', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00236', 'APP-2025-00336', '2025-11-20', '2025-11-20', '2026-11-19', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00337', 'AP-00095', 'GF-00075', '2025-11-05', 'New', 'Approved', '2025-11-17', 'LC03', 'Mabini East', 'ACQ-61619-25', '2025-07-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00337', 1, 'Identity', 'DOC-803473', '2025-11-05', 'Accepted', '2025-11-06', NULL),
('APP-2025-00337', 2, 'Registration', 'FILE-426547', '2025-11-10', 'Accepted', '2025-11-14', NULL),
('APP-2025-00337', 3, 'Acquisition', 'ACQ-61619-25', '2025-11-07', 'Accepted', '2025-11-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000333', 'APP-2025-00337', '2025-11-15', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00237', 'APP-2025-00337', '2025-11-19', '2025-11-19', '2026-11-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00338', 'AP-00003', 'GF-00093', '2025-11-06', 'New', 'Approved', '2025-11-17', 'LC05', 'Santa Elena', 'ACQ-48590-25', '2025-07-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00338', 1, 'Identity', 'FILE-767796', '2025-11-06', 'Accepted', '2025-11-11', NULL),
('APP-2025-00338', 2, 'Registration', 'DOC-172954', '2025-11-10', 'Accepted', '2025-11-17', NULL),
('APP-2025-00338', 3, 'Acquisition', 'ACQ-48590-25', '2025-11-09', 'Accepted', '2025-11-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000334', 'APP-2025-00338', '2025-11-07', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00238', 'APP-2025-00338', '2025-11-19', '2025-11-19', '2026-11-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00339', 'AP-00171', 'GF-00103', '2025-11-07', 'New', 'Approved', '2025-11-30', 'LC01', 'Luntian Central', 'ACQ-81647-25', '2025-10-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00339', 1, 'Identity', 'DOC-439765', '2025-11-07', 'Accepted', '2025-11-09', NULL),
('APP-2025-00339', 2, 'Registration', 'FILE-393322', '2025-11-08', 'Accepted', '2025-11-15', NULL),
('APP-2025-00339', 3, 'Acquisition', 'ACQ-81647-25', '2025-11-12', 'Accepted', '2025-11-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000335', 'APP-2025-00339', '2025-11-14', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00239', 'APP-2025-00339', '2025-12-04', '2025-12-04', '2026-12-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00340', 'AP-00064', 'GF-00001', '2025-11-07', 'Replacement', 'Approved', '2025-11-28', 'LC07', 'Pulo Verde', NULL, NULL, NULL, NULL, '2025-11-01', 'IR-2025-2897');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00340', 1, 'Identity', 'DOC-263931', '2025-11-07', 'Accepted', '2025-11-09', NULL),
('APP-2025-00340', 2, 'Registration', 'REF-226644', '2025-11-10', 'Accepted', '2025-11-15', NULL),
('APP-2025-00340', 3, 'Incident', 'IR-2025-2897', '2025-11-11', 'Accepted', '2025-11-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000336', 'APP-2025-00340', '2025-11-15', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00240', 'APP-2025-00340', '2025-12-01', '2025-12-01', '2026-11-30', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00341', 'AP-00018', 'GF-00147', '2025-11-09', 'New', 'Rejected', '2025-11-20', 'LC05', 'Santa Elena', 'ACQ-69527-25', '2025-08-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00341', 1, 'Identity', 'FILE-761948', '2025-11-09', 'Pending', NULL, NULL),
('APP-2025-00341', 2, 'Registration', 'REF-278231', '2025-11-14', 'Accepted', '2025-11-18', NULL),
('APP-2025-00341', 3, 'Acquisition', 'ACQ-69527-25', '2025-11-14', 'Accepted', '2025-11-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000337', 'APP-2025-00341', '2025-11-13', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00342', 'AP-00001', 'GF-00146', '2025-11-09', 'New', 'Approved', '2025-11-23', 'LC01', 'Luntian Central', 'ACQ-20187-25', '2025-10-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00342', 1, 'Identity', 'REF-535225', '2025-11-09', 'Accepted', '2025-11-14', NULL),
('APP-2025-00342', 2, 'Registration', 'REF-605713', '2025-11-12', 'Accepted', '2025-11-18', NULL),
('APP-2025-00342', 3, 'Acquisition', 'ACQ-20187-25', '2025-11-14', 'Accepted', '2025-11-17', NULL),
('APP-2025-00342', 4, 'Other', 'DOC-756522', '2025-11-11', 'Accepted', '2025-11-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000338', 'APP-2025-00342', '2025-11-12', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00241', 'APP-2025-00342', '2025-11-24', '2025-11-24', '2026-11-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00343', 'AP-00147', 'GF-00001', '2025-11-10', 'New', 'Approved', '2025-12-03', 'LC03', 'Mabini East', 'ACQ-97722-25', '2025-11-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00343', 1, 'Identity', 'REF-132318', '2025-11-10', 'Accepted', '2025-11-14', NULL),
('APP-2025-00343', 2, 'Registration', 'DOC-39256', '2025-11-15', 'Accepted', '2025-11-20', NULL),
('APP-2025-00343', 3, 'Acquisition', 'ACQ-97722-25', '2025-11-14', 'Accepted', '2025-11-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000339', 'APP-2025-00343', '2025-11-21', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00242', 'APP-2025-00343', '2025-12-05', '2025-12-05', '2026-12-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00344', 'AP-00175', 'GF-00118', '2025-11-10', 'New', 'Submitted', NULL, 'LC01', 'Luntian Central', 'ACQ-29906-25', '2025-11-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00344', 1, 'Identity', 'FILE-786490', '2025-11-10', 'Pending', NULL, NULL),
('APP-2025-00344', 2, 'Registration', 'FILE-281061', '2025-11-10', 'Pending', NULL, NULL),
('APP-2025-00344', 3, 'Acquisition', 'ACQ-29906-25', '2025-11-13', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00345', 'AP-00132', 'GF-00109', '2025-11-12', 'New', 'Withdrawn', NULL, 'LC02', 'San Isidro Heights', 'ACQ-44116-25', '2025-08-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00345', 1, 'Identity', 'FILE-804045', '2025-11-12', 'Accepted', '2025-11-14', NULL),
('APP-2025-00345', 2, 'Registration', 'REF-584687', '2025-11-14', 'Pending', NULL, NULL),
('APP-2025-00345', 3, 'Acquisition', 'ACQ-44116-25', '2025-11-12', 'Accepted', '2025-11-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000340', 'APP-2025-00345', '2025-11-15', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00346', 'AP-00036', 'GF-00064', '2025-11-14', 'Replacement', 'Approved', '2025-12-04', 'LC06', 'Maligaya', NULL, NULL, NULL, NULL, '2025-10-22', 'IR-2025-4147');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00346', 1, 'Identity', 'DOC-695126', '2025-11-14', 'Accepted', '2025-11-15', NULL),
('APP-2025-00346', 2, 'Registration', 'REF-146732', '2025-11-15', 'Accepted', '2025-11-21', NULL),
('APP-2025-00346', 3, 'Incident', 'IR-2025-4147', '2025-11-15', 'Accepted', '2025-11-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000341', 'APP-2025-00346', '2025-11-20', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00243', 'APP-2025-00346', '2025-12-07', '2025-12-07', '2026-12-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00347', 'AP-00135', 'GF-00116', '2025-11-16', 'New', 'Approved', '2025-11-29', 'LC01', 'Luntian Central', 'ACQ-86968-25', '2025-10-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00347', 1, 'Identity', 'REF-453159', '2025-11-16', 'Accepted', '2025-11-22', NULL),
('APP-2025-00347', 2, 'Registration', 'DOC-839306', '2025-11-21', 'Accepted', '2025-11-28', NULL),
('APP-2025-00347', 3, 'Acquisition', 'ACQ-86968-25', '2025-11-20', 'Accepted', '2025-11-26', NULL),
('APP-2025-00347', 4, 'Other', 'FILE-811412', '2025-11-17', 'Accepted', '2025-11-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000342', 'APP-2025-00347', '2025-11-22', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00244', 'APP-2025-00347', '2025-12-01', '2025-12-01', '2026-11-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00348', 'AP-00190', 'GF-00016', '2025-11-16', 'Replacement', 'Rejected', '2025-11-30', 'LC02', 'San Isidro Heights', NULL, NULL, NULL, NULL, '2025-10-24', 'IR-2025-1805');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00348', 1, 'Identity', 'DOC-951531', '2025-11-16', 'Accepted', '2025-11-18', NULL),
('APP-2025-00348', 2, 'Registration', 'DOC-47614', '2025-11-20', 'Accepted', '2025-11-21', NULL),
('APP-2025-00348', 3, 'Incident', 'IR-2025-1805', '2025-11-16', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00349', 'AP-00142', 'GF-00010', '2025-11-17', 'New', 'Approved', '2025-12-02', 'LC07', 'Pulo Verde', 'ACQ-41305-25', '2025-08-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00349', 1, 'Identity', 'DOC-708871', '2025-11-17', 'Accepted', '2025-11-18', NULL),
('APP-2025-00349', 2, 'Registration', 'DOC-317196', '2025-11-19', 'Accepted', '2025-11-26', NULL),
('APP-2025-00349', 3, 'Acquisition', 'ACQ-41305-25', '2025-11-17', 'Accepted', '2025-11-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000343', 'APP-2025-00349', '2025-11-28', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00245', 'APP-2025-00349', '2025-12-07', '2025-12-07', '2026-12-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00350', 'AP-00103', 'GF-00084', '2025-11-17', 'New', 'Approved', '2025-11-25', 'LC07', 'Pulo Verde', 'ACQ-98266-25', '2025-10-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00350', 1, 'Identity', 'FILE-501662', '2025-11-17', 'Accepted', '2025-11-18', NULL),
('APP-2025-00350', 2, 'Registration', 'DOC-924439', '2025-11-21', 'Accepted', '2025-11-25', NULL),
('APP-2025-00350', 3, 'Acquisition', 'ACQ-98266-25', '2025-11-17', 'Accepted', '2025-11-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000344', 'APP-2025-00350', '2025-11-25', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00246', 'APP-2025-00350', '2025-11-28', '2025-11-28', '2026-11-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00351', 'AP-00078', 'GF-00037', '2025-11-17', 'Renewal', 'Approved', '2025-11-22', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00064', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00351', 1, 'Identity', 'FILE-935166', '2025-11-17', 'Accepted', '2025-11-20', NULL),
('APP-2025-00351', 2, 'Registration', 'REF-134891', '2025-11-19', 'Accepted', '2025-11-22', NULL),
('APP-2025-00351', 3, 'PriorPermit', 'PM-2025-00064', '2025-11-17', 'Accepted', '2025-11-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000345', 'APP-2025-00351', '2025-11-22', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00247', 'APP-2025-00351', '2025-11-22', '2025-11-22', '2026-11-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00352', 'AP-00109', 'GF-00023', '2025-11-18', 'New', 'Approved', '2025-11-28', 'LC03', 'Mabini East', 'ACQ-37910-25', '2025-08-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00352', 1, 'Identity', 'FILE-277714', '2025-11-18', 'Accepted', '2025-11-23', NULL),
('APP-2025-00352', 2, 'Registration', 'REF-310867', '2025-11-21', 'Accepted', '2025-11-24', NULL),
('APP-2025-00352', 3, 'Acquisition', 'ACQ-37910-25', '2025-11-19', 'Accepted', '2025-11-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000346', 'APP-2025-00352', '2025-11-27', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00248', 'APP-2025-00352', '2025-11-30', '2025-11-30', '2026-11-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00353', 'AP-00078', 'GF-00037', '2025-11-18', 'Renewal', 'Approved', '2025-12-11', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00064', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00353', 1, 'Identity', 'REF-767170', '2025-11-18', 'Accepted', '2025-11-25', NULL),
('APP-2025-00353', 2, 'Registration', 'REF-143614', '2025-11-20', 'Accepted', '2025-11-23', NULL),
('APP-2025-00353', 3, 'PriorPermit', 'PM-2025-00064', '2025-11-22', 'Accepted', '2025-11-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000347', 'APP-2025-00353', '2025-11-27', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00249', 'APP-2025-00353', '2025-12-15', '2025-12-15', '2026-12-14', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00354', 'AP-00112', 'GF-00165', '2025-11-18', 'Renewal', 'Approved', '2025-11-22', 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00086', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00354', 1, 'Identity', 'FILE-383208', '2025-11-18', 'Accepted', '2025-11-20', NULL),
('APP-2025-00354', 2, 'Registration', 'FILE-479208', '2025-11-22', 'Accepted', '2025-11-22', NULL),
('APP-2025-00354', 3, 'PriorPermit', 'PM-2025-00086', '2025-11-18', 'Accepted', '2025-11-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000348', 'APP-2025-00354', '2025-11-22', 350, 'BankTransfer'),
('OR-2025-000349', 'APP-2025-00354', '2025-11-22', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00250', 'APP-2025-00354', '2025-11-24', '2025-11-24', '2026-11-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00355', 'AP-00013', 'GF-00101', '2025-11-19', 'Renewal', 'Approved', '2025-12-02', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00084', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00355', 1, 'Identity', 'FILE-930593', '2025-11-19', 'Accepted', '2025-11-24', NULL),
('APP-2025-00355', 2, 'Registration', 'FILE-657748', '2025-11-21', 'Accepted', '2025-11-26', NULL),
('APP-2025-00355', 3, 'PriorPermit', 'PM-2025-00084', '2025-11-21', 'Accepted', '2025-11-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000350', 'APP-2025-00355', '2025-11-19', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00251', 'APP-2025-00355', '2025-12-07', '2025-12-07', '2026-12-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00356', 'AP-00001', 'GF-00098', '2025-11-20', 'New', 'Approved', '2025-12-08', 'LC01', 'Luntian Central', 'ACQ-31815-25', '2025-08-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00356', 1, 'Identity', 'FILE-898500', '2025-11-20', 'Accepted', '2025-11-24', NULL),
('APP-2025-00356', 2, 'Registration', 'DOC-775476', '2025-11-25', 'Accepted', '2025-11-27', NULL),
('APP-2025-00356', 3, 'Acquisition', 'ACQ-31815-25', '2025-11-25', 'Accepted', '2025-11-30', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00252', 'APP-2025-00356', '2025-12-12', '2025-12-12', '2026-12-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00357', 'AP-00087', 'GF-00064', '2025-11-20', 'New', 'Approved', '2025-11-23', 'LC03', 'Mabini East', 'ACQ-97445-25', '2025-09-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00357', 1, 'Identity', 'DOC-117902', '2025-11-20', 'Accepted', '2025-11-23', NULL),
('APP-2025-00357', 2, 'Registration', 'DOC-51770', '2025-11-23', 'Accepted', '2025-11-23', NULL),
('APP-2025-00357', 3, 'Acquisition', 'ACQ-97445-25', '2025-11-23', 'Accepted', '2025-11-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000351', 'APP-2025-00357', '2025-11-23', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00253', 'APP-2025-00357', '2025-11-23', '2025-11-23', '2026-11-22', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00358', 'AP-00057', 'GF-00121', '2025-11-21', 'New', 'Approved', '2025-12-22', 'LC03', 'Mabini East', 'ACQ-14523-25', '2025-09-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00358', 1, 'Identity', 'DOC-710847', '2025-11-21', 'Accepted', '2025-11-23', NULL),
('APP-2025-00358', 2, 'Registration', 'FILE-259531', '2025-11-26', 'Accepted', '2025-11-29', NULL),
('APP-2025-00358', 3, 'Acquisition', 'ACQ-14523-25', '2025-11-24', 'Accepted', '2025-11-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000352', 'APP-2025-00358', '2025-11-23', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00254', 'APP-2025-00358', '2025-12-24', '2025-12-24', '2026-12-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00359', 'AP-00148', 'GF-00027', '2025-11-22', 'New', 'Approved', '2025-12-12', 'LC06', 'Maligaya', 'ACQ-21450-25', '2025-09-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00359', 1, 'Identity', 'REF-115413', '2025-11-22', 'Accepted', '2025-11-26', NULL),
('APP-2025-00359', 2, 'Registration', 'FILE-89081', '2025-11-23', 'Accepted', '2025-11-28', NULL),
('APP-2025-00359', 3, 'Acquisition', 'ACQ-21450-25', '2025-11-22', 'Accepted', '2025-11-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000353', 'APP-2025-00359', '2025-11-30', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00255', 'APP-2025-00359', '2025-12-15', '2025-12-15', '2026-12-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00360', 'AP-00123', 'GF-00048', '2025-11-23', 'Renewal', 'Approved', '2025-12-16', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00078', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00360', 1, 'Identity', 'FILE-476867', '2025-11-23', 'Accepted', '2025-11-24', NULL),
('APP-2025-00360', 2, 'Registration', 'DOC-90348', '2025-11-26', 'Accepted', '2025-11-29', NULL),
('APP-2025-00360', 3, 'PriorPermit', 'PM-2025-00078', '2025-11-24', 'Accepted', '2025-12-01', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00256', 'APP-2025-00360', '2025-12-16', '2025-12-16', '2026-12-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00361', 'AP-00090', 'GF-00118', '2025-11-24', 'New', 'Approved', '2025-11-28', 'LC03', 'Mabini East', 'ACQ-35062-25', '2025-10-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00361', 1, 'Identity', 'REF-414078', '2025-11-24', 'Accepted', '2025-11-28', NULL),
('APP-2025-00361', 2, 'Registration', 'DOC-461209', '2025-11-24', 'Accepted', '2025-11-28', NULL),
('APP-2025-00361', 3, 'Acquisition', 'ACQ-35062-25', '2025-11-28', 'Accepted', '2025-11-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000354', 'APP-2025-00361', '2025-11-28', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00257', 'APP-2025-00361', '2025-12-02', '2025-12-02', '2026-12-01', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00362', 'AP-00126', 'GF-00132', '2025-11-27', 'New', 'Rejected', '2025-12-19', 'LC05', 'Santa Elena', 'ACQ-52043-25', '2025-10-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00362', 1, 'Identity', 'FILE-235647', '2025-11-27', 'NeedsCorrection', '2025-11-28', 'A clearer copy of the reference portion is requested.'),
('APP-2025-00362', 2, 'Registration', 'DOC-202970', '2025-11-28', 'Accepted', '2025-11-29', NULL),
('APP-2025-00362', 3, 'Acquisition', 'ACQ-52043-25', '2025-12-02', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000355', 'APP-2025-00362', '2025-11-30', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00363', 'AP-00091', 'GF-00120', '2025-11-27', 'New', 'Approved', '2025-12-07', 'LC02', 'San Isidro Heights', 'ACQ-90928-25', '2025-08-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00363', 1, 'Identity', 'FILE-882361', '2025-11-27', 'Accepted', '2025-11-30', NULL),
('APP-2025-00363', 2, 'Registration', 'REF-360199', '2025-11-27', 'Accepted', '2025-12-02', NULL),
('APP-2025-00363', 3, 'Acquisition', 'ACQ-90928-25', '2025-11-30', 'Accepted', '2025-12-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000356', 'APP-2025-00363', '2025-12-02', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00258', 'APP-2025-00363', '2025-12-09', '2025-12-09', '2026-12-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00364', 'AP-00146', 'GF-00125', '2025-11-28', 'New', 'Approved', '2025-12-08', 'LC01', 'Luntian Central', 'ACQ-21849-25', '2025-10-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00364', 1, 'Identity', 'FILE-581236', '2025-11-28', 'Accepted', '2025-12-03', NULL),
('APP-2025-00364', 2, 'Registration', 'FILE-972613', '2025-12-02', 'Accepted', '2025-12-08', NULL),
('APP-2025-00364', 3, 'Acquisition', 'ACQ-21849-25', '2025-11-28', 'Accepted', '2025-12-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000357', 'APP-2025-00364', '2025-12-05', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00259', 'APP-2025-00364', '2025-12-09', '2025-12-09', '2026-12-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00365', 'AP-00119', 'GF-00018', '2025-11-28', 'New', 'Approved', '2025-12-08', 'LC01', 'Luntian Central', 'ACQ-20964-25', '2025-09-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00365', 1, 'Identity', 'FILE-55539', '2025-11-28', 'Accepted', '2025-12-04', NULL),
('APP-2025-00365', 2, 'Registration', 'REF-20836', '2025-11-30', 'Accepted', '2025-12-07', NULL),
('APP-2025-00365', 3, 'Acquisition', 'ACQ-20964-25', '2025-11-29', 'Accepted', '2025-12-02', NULL),
('APP-2025-00365', 4, 'Other', 'DOC-365994', '2025-11-29', 'Accepted', '2025-12-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000358', 'APP-2025-00365', '2025-11-29', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00260', 'APP-2025-00365', '2025-12-13', '2025-12-13', '2026-12-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00366', 'AP-00146', 'GF-00148', '2025-11-28', 'New', 'Approved', '2025-12-03', 'LC01', 'Luntian Central', 'ACQ-76165-25', '2025-09-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00366', 1, 'Identity', 'FILE-407366', '2025-11-28', 'Accepted', '2025-12-02', NULL),
('APP-2025-00366', 2, 'Registration', 'FILE-665640', '2025-11-30', 'Accepted', '2025-12-01', NULL),
('APP-2025-00366', 3, 'Acquisition', 'ACQ-76165-25', '2025-12-02', 'Accepted', '2025-12-03', NULL),
('APP-2025-00366', 4, 'Other', 'FILE-607389', '2025-11-29', 'Accepted', '2025-12-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000359', 'APP-2025-00366', '2025-12-02', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00261', 'APP-2025-00366', '2025-12-08', '2025-12-08', '2026-12-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00367', 'AP-00024', 'GF-00031', '2025-12-01', 'New', 'Approved', '2025-12-17', 'LC07', 'Pulo Verde', 'ACQ-21538-25', '2025-10-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00367', 1, 'Identity', 'FILE-998959', '2025-12-01', 'Accepted', '2025-12-06', NULL),
('APP-2025-00367', 2, 'Registration', 'FILE-926838', '2025-12-05', 'Accepted', '2025-12-12', NULL),
('APP-2025-00367', 3, 'Acquisition', 'ACQ-21538-25', '2025-12-03', 'Accepted', '2025-12-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000360', 'APP-2025-00367', '2025-12-04', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00262', 'APP-2025-00367', '2025-12-21', '2025-12-21', '2026-12-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00368', 'AP-00124', 'GF-00007', '2025-12-01', 'Renewal', 'Approved', '2026-01-28', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00039', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00368', 1, 'Identity', 'DOC-118523', '2025-12-01', 'Accepted', '2025-12-06', NULL),
('APP-2025-00368', 2, 'Registration', 'FILE-882002', '2025-12-02', 'Accepted', '2025-12-08', NULL),
('APP-2025-00368', 3, 'PriorPermit', 'PM-2025-00039', '2025-12-05', 'Accepted', '2025-12-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000361', 'APP-2025-00368', '2025-12-01', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00263', 'APP-2025-00368', '2026-02-01', '2026-02-01', '2027-01-31', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00369', 'AP-00161', 'GF-00055', '2025-12-01', 'Renewal', 'Approved', '2025-12-20', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00055', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00369', 1, 'Identity', 'REF-840082', '2025-12-01', 'Accepted', '2025-12-08', NULL),
('APP-2025-00369', 2, 'Registration', 'DOC-646632', '2025-12-04', 'Accepted', '2025-12-06', NULL),
('APP-2025-00369', 3, 'PriorPermit', 'PM-2025-00055', '2025-12-03', 'Accepted', '2025-12-10', NULL),
('APP-2025-00369', 4, 'Other', 'REF-332766', '2025-12-03', 'Accepted', '2025-12-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000362', 'APP-2025-00369', '2025-12-13', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00264', 'APP-2025-00369', '2025-12-25', '2025-12-25', '2026-12-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00370', 'AP-00105', 'GF-00106', '2025-12-01', 'Renewal', 'Rejected', '2025-12-19', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00029', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00370', 1, 'Identity', 'DOC-140710', '2025-12-01', 'NeedsCorrection', '2025-12-02', 'A clearer copy of the reference portion is requested.'),
('APP-2025-00370', 2, 'Registration', 'DOC-83210', '2025-12-06', 'Accepted', '2025-12-12', NULL),
('APP-2025-00370', 3, 'PriorPermit', 'PM-2025-00029', '2025-12-06', 'Accepted', '2025-12-11', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00371', 'AP-00161', 'GF-00021', '2025-12-03', 'New', 'Approved', '2025-12-15', 'LC01', 'Luntian Central', 'ACQ-94426-25', '2025-10-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00371', 1, 'Identity', 'FILE-613822', '2025-12-03', 'Accepted', '2025-12-05', NULL),
('APP-2025-00371', 2, 'Registration', 'REF-940031', '2025-12-05', 'Accepted', '2025-12-11', NULL),
('APP-2025-00371', 3, 'Acquisition', 'ACQ-94426-25', '2025-12-08', 'Accepted', '2025-12-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000363', 'APP-2025-00371', '2025-12-08', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00265', 'APP-2025-00371', '2025-12-17', '2025-12-17', '2026-12-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00372', 'AP-00172', 'GF-00122', '2025-12-03', 'Renewal', 'Rejected', '2025-12-22', 'LC06', 'Maligaya', NULL, NULL, 'PM-2025-00126', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00372', 1, 'Identity', 'FILE-274705', '2025-12-03', 'NeedsCorrection', '2025-12-08', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00372', 2, 'Registration', 'FILE-436811', '2025-12-05', 'Accepted', '2025-12-10', NULL),
('APP-2025-00372', 3, 'PriorPermit', 'PM-2025-00126', '2025-12-04', 'NeedsCorrection', '2025-12-06', 'The submitted name requires clarification against the application.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000364', 'APP-2025-00372', '2025-12-11', 600, 'Cash'),
('OR-2025-000365', 'APP-2025-00372', '2025-12-10', 250, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00373', 'AP-00118', 'GF-00074', '2025-12-03', 'Replacement', 'Approved', '2025-12-07', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2025-11-19', 'IR-2025-6731');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00373', 1, 'Identity', 'DOC-937924', '2025-12-03', 'Accepted', '2025-12-07', NULL),
('APP-2025-00373', 2, 'Registration', 'DOC-427170', '2025-12-07', 'Accepted', '2025-12-07', NULL),
('APP-2025-00373', 3, 'Incident', 'IR-2025-6731', '2025-12-03', 'Accepted', '2025-12-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000366', 'APP-2025-00373', '2025-12-03', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00266', 'APP-2025-00373', '2025-12-12', '2025-12-12', '2026-12-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00374', 'AP-00017', 'GF-00064', '2025-12-05', 'New', 'Approved', '2025-12-27', 'LC03', 'Mabini East', 'ACQ-45863-25', '2025-10-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00374', 1, 'Identity', 'DOC-88417', '2025-12-05', 'Accepted', '2025-12-07', NULL),
('APP-2025-00374', 2, 'Registration', 'FILE-898033', '2025-12-08', 'Accepted', '2025-12-14', NULL),
('APP-2025-00374', 3, 'Acquisition', 'ACQ-45863-25', '2025-12-09', 'Accepted', '2025-12-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000367', 'APP-2025-00374', '2025-12-11', 450, 'BankTransfer'),
('OR-2025-000368', 'APP-2025-00374', '2025-12-11', 150, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00267', 'APP-2025-00374', '2025-12-29', '2025-12-29', '2026-12-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00375', 'AP-00017', 'GF-00162', '2025-12-05', 'Replacement', 'Approved', '2026-01-02', 'LC03', 'Mabini East', NULL, NULL, NULL, NULL, '2025-11-11', 'IR-2025-2699');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00375', 1, 'Identity', 'REF-770329', '2025-12-05', 'Accepted', '2025-12-07', NULL),
('APP-2025-00375', 2, 'Registration', 'DOC-774232', '2025-12-06', 'Accepted', '2025-12-10', NULL),
('APP-2025-00375', 3, 'Incident', 'IR-2025-2699', '2025-12-10', 'Accepted', '2025-12-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000369', 'APP-2025-00375', '2025-12-06', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00268', 'APP-2025-00375', '2026-01-05', '2026-01-05', '2027-01-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00376', 'AP-00180', 'GF-00147', '2025-12-07', 'New', 'Withdrawn', NULL, 'LC03', 'Mabini East', 'ACQ-23254-25', '2025-08-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00376', 1, 'Identity', 'DOC-218870', '2025-12-07', 'Accepted', '2025-12-13', NULL),
('APP-2025-00376', 2, 'Registration', 'DOC-868523', '2025-12-11', 'Pending', NULL, NULL),
('APP-2025-00376', 3, 'Acquisition', 'ACQ-23254-25', '2025-12-07', 'NeedsCorrection', '2025-12-14', 'The recorded reference must be verified with the submitted copy.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000370', 'APP-2025-00376', '2025-12-09', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00377', 'AP-00107', 'GF-00152', '2025-12-07', 'New', 'Approved', '2025-12-23', 'LC06', 'Maligaya', 'ACQ-12876-25', '2025-08-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00377', 1, 'Identity', 'FILE-789671', '2025-12-07', 'Accepted', '2025-12-11', NULL),
('APP-2025-00377', 2, 'Registration', 'FILE-671641', '2025-12-08', 'Accepted', '2025-12-14', NULL),
('APP-2025-00377', 3, 'Acquisition', 'ACQ-12876-25', '2025-12-10', 'Accepted', '2025-12-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000371', 'APP-2025-00377', '2025-12-08', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00269', 'APP-2025-00377', '2025-12-26', '2025-12-26', '2026-12-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00378', 'AP-00001', 'GF-00143', '2025-12-07', 'New', 'Approved', '2025-12-21', 'LC01', 'Luntian Central', 'ACQ-85178-25', '2025-11-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00378', 1, 'Identity', 'REF-592587', '2025-12-07', 'Accepted', '2025-12-13', NULL),
('APP-2025-00378', 2, 'Registration', 'DOC-431869', '2025-12-11', 'Accepted', '2025-12-14', NULL),
('APP-2025-00378', 3, 'Acquisition', 'ACQ-85178-25', '2025-12-12', 'Accepted', '2025-12-16', NULL),
('APP-2025-00378', 4, 'Other', 'REF-795418', '2025-12-09', 'Accepted', '2025-12-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000372', 'APP-2025-00378', '2025-12-16', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00270', 'APP-2025-00378', '2025-12-24', '2025-12-24', '2026-12-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00379', 'AP-00161', 'GF-00147', '2025-12-09', 'New', 'Approved', '2025-12-17', 'LC01', 'Luntian Central', 'ACQ-18638-25', '2025-08-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00379', 1, 'Identity', 'REF-582113', '2025-12-09', 'Accepted', '2025-12-13', NULL),
('APP-2025-00379', 2, 'Registration', 'DOC-120205', '2025-12-14', 'Accepted', '2025-12-17', NULL),
('APP-2025-00379', 3, 'Acquisition', 'ACQ-18638-25', '2025-12-11', 'Accepted', '2025-12-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000373', 'APP-2025-00379', '2025-12-11', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00271', 'APP-2025-00379', '2025-12-17', '2025-12-17', '2026-12-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00380', 'AP-00128', 'GF-00015', '2025-12-10', 'New', 'Approved', '2025-12-25', 'LC01', 'Luntian Central', 'ACQ-93429-25', '2025-08-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00380', 1, 'Identity', 'REF-219898', '2025-12-10', 'Accepted', '2025-12-16', NULL),
('APP-2025-00380', 2, 'Registration', 'REF-474568', '2025-12-12', 'Accepted', '2025-12-13', NULL),
('APP-2025-00380', 3, 'Acquisition', 'ACQ-93429-25', '2025-12-15', 'Accepted', '2025-12-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000374', 'APP-2025-00380', '2025-12-16', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00272', 'APP-2025-00380', '2025-12-28', '2025-12-28', '2026-12-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00381', 'AP-00132', 'GF-00093', '2025-12-11', 'New', 'Submitted', NULL, 'LC02', 'San Isidro Heights', 'ACQ-52830-25', '2025-12-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00381', 1, 'Identity', 'DOC-800531', '2025-12-11', 'Pending', NULL, NULL),
('APP-2025-00381', 2, 'Registration', 'FILE-96061', '2025-12-13', 'Pending', NULL, NULL),
('APP-2025-00381', 3, 'Acquisition', 'ACQ-52830-25', '2025-12-12', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000375', 'APP-2025-00381', '2025-12-18', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00382', 'AP-00172', 'GF-00152', '2025-12-11', 'Renewal', 'UnderReview', NULL, 'LC06', 'Maligaya', NULL, NULL, 'PM-2025-00132', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00382', 1, 'Identity', 'DOC-376218', '2025-12-11', 'Pending', NULL, NULL),
('APP-2025-00382', 2, 'Registration', 'FILE-77600', '2025-12-16', 'NeedsCorrection', '2025-12-20', 'The recorded reference must be verified with the submitted copy.'),
('APP-2025-00382', 3, 'PriorPermit', 'PM-2025-00132', '2025-12-12', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000376', 'APP-2025-00382', '2025-12-13', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00383', 'AP-00118', 'GF-00135', '2025-12-12', 'New', 'Approved', '2026-01-19', 'LC01', 'Luntian Central', 'ACQ-69079-25', '2025-08-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00383', 1, 'Identity', 'REF-378285', '2025-12-12', 'Accepted', '2025-12-19', NULL),
('APP-2025-00383', 2, 'Registration', 'REF-745946', '2025-12-17', 'Accepted', '2025-12-23', NULL),
('APP-2025-00383', 3, 'Acquisition', 'ACQ-69079-25', '2025-12-16', 'Accepted', '2025-12-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000377', 'APP-2025-00383', '2025-12-23', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00273', 'APP-2025-00383', '2026-01-20', '2026-01-20', '2027-01-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00384', 'AP-00158', 'GF-00061', '2025-12-13', 'New', 'Approved', '2026-01-25', 'LC05', 'Santa Elena', 'ACQ-51139-25', '2025-10-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00384', 1, 'Identity', 'FILE-466321', '2025-12-13', 'Accepted', '2025-12-14', NULL),
('APP-2025-00384', 2, 'Registration', 'FILE-921516', '2025-12-15', 'Accepted', '2025-12-20', NULL),
('APP-2025-00384', 3, 'Acquisition', 'ACQ-51139-25', '2025-12-18', 'Accepted', '2025-12-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000378', 'APP-2025-00384', '2025-12-25', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00274', 'APP-2025-00384', '2026-01-28', '2026-01-28', '2027-01-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00385', 'AP-00006', 'GF-00068', '2025-12-15', 'New', 'Approved', '2026-01-22', 'LC03', 'Mabini East', 'ACQ-74891-25', '2025-08-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00385', 1, 'Identity', 'DOC-778281', '2025-12-15', 'Accepted', '2025-12-18', NULL),
('APP-2025-00385', 2, 'Registration', 'FILE-433278', '2025-12-15', 'Accepted', '2025-12-21', NULL),
('APP-2025-00385', 3, 'Acquisition', 'ACQ-74891-25', '2025-12-19', 'Accepted', '2025-12-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000379', 'APP-2025-00385', '2025-12-26', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00386', 'AP-00042', 'GF-00058', '2025-12-16', 'New', 'Approved', '2025-12-26', 'LC03', 'Mabini East', 'ACQ-63369-25', '2025-09-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00386', 1, 'Identity', 'DOC-811541', '2025-12-16', 'Accepted', '2025-12-20', NULL),
('APP-2025-00386', 2, 'Registration', 'REF-162333', '2025-12-16', 'Accepted', '2025-12-21', NULL),
('APP-2025-00386', 3, 'Acquisition', 'ACQ-63369-25', '2025-12-17', 'Accepted', '2025-12-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000380', 'APP-2025-00386', '2025-12-19', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00275', 'APP-2025-00386', '2025-12-29', '2025-12-29', '2026-12-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00387', 'AP-00164', 'GF-00073', '2025-12-17', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-61648-25', '2025-08-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00387', 1, 'Identity', 'REF-676901', '2025-12-17', 'Accepted', '2025-12-19', NULL),
('APP-2025-00387', 2, 'Registration', 'REF-709562', '2025-12-21', 'NeedsCorrection', '2025-12-26', 'A clearer copy of the reference portion is requested.'),
('APP-2025-00387', 3, 'Acquisition', 'ACQ-61648-25', '2025-12-18', 'Accepted', '2025-12-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000381', 'APP-2025-00387', '2025-12-27', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00388', 'AP-00057', 'GF-00019', '2025-12-18', 'Renewal', 'Approved', '2025-12-23', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00137', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00388', 1, 'Identity', 'DOC-92394', '2025-12-18', 'Accepted', '2025-12-19', NULL),
('APP-2025-00388', 2, 'Registration', 'FILE-162508', '2025-12-18', 'Accepted', '2025-12-19', NULL),
('APP-2025-00388', 3, 'PriorPermit', 'PM-2025-00137', '2025-12-18', 'Accepted', '2025-12-23', NULL),
('APP-2025-00388', 4, 'Other', 'REF-224457', '2025-12-21', 'Accepted', '2025-12-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000382', 'APP-2025-00388', '2025-12-21', 750, 'Online'),
('OR-2025-000383', 'APP-2025-00388', '2025-12-23', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00276', 'APP-2025-00388', '2025-12-27', '2025-12-27', '2026-12-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00389', 'AP-00058', 'GF-00090', '2025-12-19', 'New', 'Approved', '2026-01-12', 'LC03', 'Mabini East', 'ACQ-88503-25', '2025-11-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00389', 1, 'Identity', 'REF-741215', '2025-12-19', 'Accepted', '2025-12-26', NULL),
('APP-2025-00389', 2, 'Registration', 'FILE-833575', '2025-12-22', 'Accepted', '2025-12-26', NULL),
('APP-2025-00389', 3, 'Acquisition', 'ACQ-88503-25', '2025-12-23', 'Accepted', '2025-12-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000384', 'APP-2025-00389', '2025-12-20', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00277', 'APP-2025-00389', '2026-01-13', '2026-01-13', '2027-01-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00390', 'AP-00166', 'GF-00086', '2025-12-19', 'New', 'Approved', '2025-12-25', 'LC05', 'Santa Elena', 'ACQ-17009-25', '2025-08-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00390', 1, 'Identity', 'REF-531434', '2025-12-19', 'Accepted', '2025-12-21', NULL),
('APP-2025-00390', 2, 'Registration', 'REF-534496', '2025-12-19', 'Accepted', '2025-12-25', NULL),
('APP-2025-00390', 3, 'Acquisition', 'ACQ-17009-25', '2025-12-20', 'Accepted', '2025-12-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000385', 'APP-2025-00390', '2025-12-25', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00278', 'APP-2025-00390', '2025-12-29', '2025-12-29', '2026-12-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00391', 'AP-00185', 'GF-00005', '2025-12-19', 'Renewal', 'Approved', '2026-02-09', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00041', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00391', 1, 'Identity', 'FILE-306140', '2025-12-19', 'Accepted', '2025-12-20', NULL),
('APP-2025-00391', 2, 'Registration', 'FILE-299656', '2025-12-24', 'Accepted', '2025-12-25', NULL),
('APP-2025-00391', 3, 'PriorPermit', 'PM-2025-00041', '2025-12-22', 'Accepted', '2025-12-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000386', 'APP-2025-00391', '2025-12-27', 450, 'Cash'),
('OR-2025-000387', 'APP-2025-00391', '2025-12-28', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00279', 'APP-2025-00391', '2026-02-13', '2026-02-13', '2027-02-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00392', 'AP-00060', 'GF-00140', '2025-12-20', 'New', 'Approved', '2025-12-27', 'LC02', 'San Isidro Heights', 'ACQ-75437-25', '2025-09-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00392', 1, 'Identity', 'DOC-60919', '2025-12-20', 'Accepted', '2025-12-22', NULL),
('APP-2025-00392', 2, 'Registration', 'FILE-374958', '2025-12-22', 'Accepted', '2025-12-27', NULL),
('APP-2025-00392', 3, 'Acquisition', 'ACQ-75437-25', '2025-12-23', 'Accepted', '2025-12-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000388', 'APP-2025-00392', '2025-12-27', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2025-00280', 'APP-2025-00392', '2025-12-30', '2025-12-30', '2026-12-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00393', 'AP-00052', 'GF-00146', '2025-12-20', 'Renewal', 'Approved', '2025-12-29', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00134', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00393', 1, 'Identity', 'FILE-483498', '2025-12-20', 'Accepted', '2025-12-22', NULL),
('APP-2025-00393', 2, 'Registration', 'FILE-139643', '2025-12-22', 'Accepted', '2025-12-24', NULL),
('APP-2025-00393', 3, 'PriorPermit', 'PM-2025-00134', '2025-12-23', 'Accepted', '2025-12-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000389', 'APP-2025-00393', '2025-12-29', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00281', 'APP-2025-00393', '2026-01-02', '2026-01-02', '2027-01-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00394', 'AP-00117', 'GF-00012', '2025-12-25', 'Replacement', 'Approved', '2026-01-13', 'LC04', 'Bagong Silangan', NULL, NULL, NULL, NULL, '2025-12-19', 'IR-2025-7614');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00394', 1, 'Identity', 'FILE-80473', '2025-12-25', 'Accepted', '2026-01-01', NULL),
('APP-2025-00394', 2, 'Registration', 'FILE-800469', '2025-12-28', 'Accepted', '2026-01-02', NULL),
('APP-2025-00394', 3, 'Incident', 'IR-2025-7614', '2025-12-29', 'Accepted', '2026-01-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2025-000390', 'APP-2025-00394', '2025-12-31', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00395', 'AP-00004', 'GF-00142', '2025-12-26', 'Replacement', 'Approved', '2026-01-16', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2025-12-07', 'IR-2025-5389');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00395', 1, 'Identity', 'DOC-119268', '2025-12-26', 'Accepted', '2025-12-30', NULL),
('APP-2025-00395', 2, 'Registration', 'FILE-18834', '2025-12-31', 'Accepted', '2026-01-06', NULL),
('APP-2025-00395', 3, 'Incident', 'IR-2025-5389', '2025-12-31', 'Accepted', '2026-01-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000391', 'APP-2025-00395', '2026-01-07', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00282', 'APP-2025-00395', '2026-01-18', '2026-01-18', '2027-01-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00396', 'AP-00059', 'GF-00030', '2025-12-28', 'New', 'Approved', '2026-01-01', 'LC05', 'Santa Elena', 'ACQ-86613-25', '2025-12-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00396', 1, 'Identity', 'REF-335683', '2025-12-28', 'Accepted', '2026-01-01', NULL),
('APP-2025-00396', 2, 'Registration', 'FILE-321799', '2025-12-28', 'Accepted', '2026-01-01', NULL),
('APP-2025-00396', 3, 'Acquisition', 'ACQ-86613-25', '2026-01-01', 'Accepted', '2026-01-01', NULL),
('APP-2025-00396', 4, 'Other', 'DOC-930045', '2026-01-01', 'Accepted', '2026-01-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000392', 'APP-2025-00396', '2026-01-01', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00283', 'APP-2025-00396', '2026-01-02', '2026-01-02', '2027-01-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00397', 'AP-00098', 'GF-00119', '2025-12-29', 'New', 'Approved', '2026-01-20', 'LC02', 'San Isidro Heights', 'ACQ-97930-25', '2025-10-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00397', 1, 'Identity', 'FILE-308881', '2025-12-29', 'Accepted', '2026-01-03', NULL),
('APP-2025-00397', 2, 'Registration', 'DOC-918892', '2025-12-30', 'Accepted', '2026-01-06', NULL),
('APP-2025-00397', 3, 'Acquisition', 'ACQ-97930-25', '2026-01-02', 'Accepted', '2026-01-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000393', 'APP-2025-00397', '2026-01-09', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00284', 'APP-2025-00397', '2026-01-25', '2026-01-25', '2027-01-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00398', 'AP-00131', 'GF-00085', '2025-12-30', 'New', 'Approved', '2026-02-13', 'LC05', 'Santa Elena', 'ACQ-55278-25', '2025-09-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00398', 1, 'Identity', 'REF-124809', '2025-12-30', 'Accepted', '2026-01-03', NULL),
('APP-2025-00398', 2, 'Registration', 'REF-497800', '2025-12-30', 'Accepted', '2026-01-03', NULL),
('APP-2025-00398', 3, 'Acquisition', 'ACQ-55278-25', '2025-12-30', 'Accepted', '2026-01-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000394', 'APP-2025-00398', '2026-01-08', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00285', 'APP-2025-00398', '2026-02-14', '2026-02-14', '2027-02-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00399', 'AP-00072', 'GF-00162', '2025-12-31', 'New', 'Rejected', '2026-02-26', 'LC08', 'San Rafael Norte', 'ACQ-63726-25', '2025-11-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00399', 1, 'Identity', 'FILE-361473', '2025-12-31', 'Accepted', '2026-01-05', NULL),
('APP-2025-00399', 2, 'Registration', 'REF-74522', '2026-01-01', 'Accepted', '2026-01-04', NULL),
('APP-2025-00399', 3, 'Acquisition', 'ACQ-63726-25', '2026-01-01', 'NeedsCorrection', '2026-01-07', 'The date on the document needs clarification.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2025-00400', 'AP-00172', 'GF-00122', '2025-12-31', 'Renewal', 'Approved', '2026-02-14', 'LC06', 'Maligaya', NULL, NULL, 'PM-2025-00126', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2025-00400', 1, 'Identity', 'FILE-678442', '2025-12-31', 'Accepted', '2026-01-05', NULL),
('APP-2025-00400', 2, 'Registration', 'FILE-992579', '2026-01-01', 'Accepted', '2026-01-08', NULL),
('APP-2025-00400', 3, 'PriorPermit', 'PM-2025-00126', '2026-01-03', 'Accepted', '2026-01-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000395', 'APP-2025-00400', '2026-01-06', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00286', 'APP-2025-00400', '2026-02-18', '2026-02-18', '2027-02-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00401', 'AP-00115', 'GF-00089', '2026-01-01', 'New', 'Approved', '2026-01-16', 'LC02', 'San Isidro Heights', 'ACQ-31683-26', '2025-11-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00401', 1, 'Identity', 'DOC-757629', '2026-01-01', 'Accepted', '2026-01-06', NULL),
('APP-2026-00401', 2, 'Registration', 'REF-466281', '2026-01-02', 'Accepted', '2026-01-06', NULL),
('APP-2026-00401', 3, 'Acquisition', 'ACQ-31683-26', '2026-01-05', 'Accepted', '2026-01-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000396', 'APP-2026-00401', '2026-01-11', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00287', 'APP-2026-00401', '2026-01-18', '2026-01-18', '2027-01-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00402', 'AP-00041', 'GF-00081', '2026-01-02', 'New', 'Approved', '2026-01-27', 'LC05', 'Santa Elena', 'ACQ-96299-26', '2025-09-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00402', 1, 'Identity', 'FILE-515392', '2026-01-02', 'Accepted', '2026-01-03', NULL),
('APP-2026-00402', 2, 'Registration', 'FILE-767365', '2026-01-02', 'Accepted', '2026-01-08', NULL),
('APP-2026-00402', 3, 'Acquisition', 'ACQ-96299-26', '2026-01-05', 'Accepted', '2026-01-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000397', 'APP-2026-00402', '2026-01-12', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00288', 'APP-2026-00402', '2026-01-28', '2026-01-28', '2027-01-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00403', 'AP-00005', 'GF-00086', '2026-01-04', 'Renewal', 'Approved', '2026-01-24', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00069', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00403', 1, 'Identity', 'FILE-549888', '2026-01-04', 'Accepted', '2026-01-05', NULL),
('APP-2026-00403', 2, 'Registration', 'REF-326616', '2026-01-07', 'Accepted', '2026-01-13', NULL),
('APP-2026-00403', 3, 'PriorPermit', 'PM-2025-00069', '2026-01-07', 'Accepted', '2026-01-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000398', 'APP-2026-00403', '2026-01-12', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00289', 'APP-2026-00403', '2026-01-29', '2026-01-29', '2027-01-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00404', 'AP-00006', 'GF-00029', '2026-01-07', 'Replacement', 'Approved', '2026-02-01', 'LC03', 'Mabini East', NULL, NULL, NULL, NULL, '2025-12-27', 'IR-2026-3710');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00404', 1, 'Identity', 'REF-902856', '2026-01-07', 'Accepted', '2026-01-12', NULL),
('APP-2026-00404', 2, 'Registration', 'DOC-299283', '2026-01-11', 'Accepted', '2026-01-18', NULL),
('APP-2026-00404', 3, 'Incident', 'IR-2026-3710', '2026-01-10', 'Accepted', '2026-01-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000399', 'APP-2026-00404', '2026-01-16', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00290', 'APP-2026-00404', '2026-02-04', '2026-02-04', '2027-02-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00405', 'AP-00074', 'GF-00145', '2026-01-08', 'New', 'Rejected', '2026-01-16', 'LC02', 'San Isidro Heights', 'ACQ-99417-26', '2025-09-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00405', 1, 'Identity', 'FILE-592731', '2026-01-08', 'Accepted', '2026-01-13', NULL),
('APP-2026-00405', 2, 'Registration', 'FILE-180659', '2026-01-08', 'Pending', NULL, NULL),
('APP-2026-00405', 3, 'Acquisition', 'ACQ-99417-26', '2026-01-12', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000400', 'APP-2026-00405', '2026-01-16', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00406', 'AP-00091', 'GF-00116', '2026-01-10', 'New', 'Approved', '2026-01-22', 'LC02', 'San Isidro Heights', 'ACQ-55167-26', '2025-11-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00406', 1, 'Identity', 'FILE-917527', '2026-01-10', 'Accepted', '2026-01-15', NULL),
('APP-2026-00406', 2, 'Registration', 'REF-912461', '2026-01-11', 'Accepted', '2026-01-16', NULL),
('APP-2026-00406', 3, 'Acquisition', 'ACQ-55167-26', '2026-01-15', 'Accepted', '2026-01-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000401', 'APP-2026-00406', '2026-01-13', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00291', 'APP-2026-00406', '2026-01-26', '2026-01-26', '2027-01-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00407', 'AP-00041', 'GF-00126', '2026-01-10', 'Renewal', 'Approved', '2026-01-26', 'LC05', 'Santa Elena', NULL, NULL, 'PM-2025-00115', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00407', 1, 'Identity', 'REF-247378', '2026-01-10', 'Accepted', '2026-01-15', NULL),
('APP-2026-00407', 2, 'Registration', 'DOC-485354', '2026-01-12', 'Accepted', '2026-01-19', NULL),
('APP-2026-00407', 3, 'PriorPermit', 'PM-2025-00115', '2026-01-14', 'Accepted', '2026-01-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000402', 'APP-2026-00407', '2026-01-13', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00292', 'APP-2026-00407', '2026-01-28', '2026-01-28', '2027-01-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00408', 'AP-00110', 'GF-00114', '2026-01-11', 'New', 'Approved', '2026-01-30', 'LC04', 'Bagong Silangan', 'ACQ-99862-26', '2025-11-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00408', 1, 'Identity', 'REF-261311', '2026-01-11', 'Accepted', '2026-01-17', NULL),
('APP-2026-00408', 2, 'Registration', 'FILE-789255', '2026-01-11', 'Accepted', '2026-01-16', NULL),
('APP-2026-00408', 3, 'Acquisition', 'ACQ-99862-26', '2026-01-13', 'Accepted', '2026-01-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000403', 'APP-2026-00408', '2026-01-13', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00293', 'APP-2026-00408', '2026-01-31', '2026-01-31', '2027-01-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00409', 'AP-00045', 'GF-00110', '2026-01-12', 'New', 'Approved', '2026-01-22', 'LC06', 'Maligaya', 'ACQ-78799-26', '2025-10-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00409', 1, 'Identity', 'DOC-13317', '2026-01-12', 'Accepted', '2026-01-19', NULL),
('APP-2026-00409', 2, 'Registration', 'REF-645549', '2026-01-15', 'Accepted', '2026-01-16', NULL),
('APP-2026-00409', 3, 'Acquisition', 'ACQ-78799-26', '2026-01-16', 'Accepted', '2026-01-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000404', 'APP-2026-00409', '2026-01-19', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00294', 'APP-2026-00409', '2026-01-25', '2026-01-25', '2027-01-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00410', 'AP-00067', 'GF-00039', '2026-01-12', 'New', 'Approved', '2026-02-01', 'LC04', 'Bagong Silangan', 'ACQ-89249-26', '2026-01-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00410', 1, 'Identity', 'DOC-47296', '2026-01-12', 'Accepted', '2026-01-16', NULL),
('APP-2026-00410', 2, 'Registration', 'DOC-412953', '2026-01-14', 'Accepted', '2026-01-20', NULL),
('APP-2026-00410', 3, 'Acquisition', 'ACQ-89249-26', '2026-01-17', 'Accepted', '2026-01-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000405', 'APP-2026-00410', '2026-01-21', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00295', 'APP-2026-00410', '2026-02-01', '2026-02-01', '2027-01-31', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00411', 'AP-00163', 'GF-00143', '2026-01-13', 'New', 'Approved', '2026-03-02', 'LC01', 'Luntian Central', 'ACQ-66097-26', '2025-11-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00411', 1, 'Identity', 'REF-861735', '2026-01-13', 'Accepted', '2026-01-20', NULL),
('APP-2026-00411', 2, 'Registration', 'FILE-320710', '2026-01-14', 'Accepted', '2026-01-16', NULL),
('APP-2026-00411', 3, 'Acquisition', 'ACQ-66097-26', '2026-01-17', 'Accepted', '2026-01-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000406', 'APP-2026-00411', '2026-01-14', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00296', 'APP-2026-00411', '2026-03-07', '2026-03-07', '2027-03-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00412', 'AP-00115', 'GF-00069', '2026-01-15', 'New', 'Withdrawn', NULL, 'LC02', 'San Isidro Heights', 'ACQ-56310-26', '2025-11-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00412', 1, 'Identity', 'DOC-318973', '2026-01-15', 'Pending', NULL, NULL),
('APP-2026-00412', 2, 'Registration', 'REF-631102', '2026-01-18', 'Pending', NULL, NULL),
('APP-2026-00412', 3, 'Acquisition', 'ACQ-56310-26', '2026-01-15', 'Accepted', '2026-01-20', NULL),
('APP-2026-00412', 4, 'Other', 'REF-655518', '2026-01-17', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000407', 'APP-2026-00412', '2026-01-17', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00413', 'AP-00059', 'GF-00152', '2026-01-16', 'New', 'Withdrawn', NULL, 'LC05', 'Santa Elena', 'ACQ-32424-26', '2025-12-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00413', 1, 'Identity', 'REF-226946', '2026-01-16', 'NeedsCorrection', '2026-01-17', 'Please provide the missing page of the supporting document.'),
('APP-2026-00413', 2, 'Registration', 'FILE-964106', '2026-01-19', 'Accepted', '2026-01-23', NULL),
('APP-2026-00413', 3, 'Acquisition', 'ACQ-32424-26', '2026-01-21', 'Accepted', '2026-01-25', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00414', 'AP-00124', 'GF-00003', '2026-01-18', 'New', 'Approved', '2026-03-08', 'LC06', 'Maligaya', 'ACQ-96255-26', '2026-01-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00414', 1, 'Identity', 'FILE-580073', '2026-01-18', 'Accepted', '2026-01-24', NULL),
('APP-2026-00414', 2, 'Registration', 'FILE-89099', '2026-01-20', 'Accepted', '2026-01-26', NULL),
('APP-2026-00414', 3, 'Acquisition', 'ACQ-96255-26', '2026-01-19', 'Accepted', '2026-01-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000408', 'APP-2026-00414', '2026-01-19', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00297', 'APP-2026-00414', '2026-03-09', '2026-03-09', '2027-03-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00415', 'AP-00185', 'GF-00141', '2026-01-20', 'New', 'Rejected', '2026-02-12', 'LC03', 'Mabini East', 'ACQ-48988-26', '2025-12-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00415', 1, 'Identity', 'FILE-435996', '2026-01-20', 'NeedsCorrection', '2026-01-21', 'The date on the document needs clarification.'),
('APP-2026-00415', 2, 'Registration', 'REF-166075', '2026-01-24', 'Accepted', '2026-01-29', NULL),
('APP-2026-00415', 3, 'Acquisition', 'ACQ-48988-26', '2026-01-23', 'Accepted', '2026-01-29', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00416', 'AP-00081', 'GF-00152', '2026-01-20', 'Renewal', 'Approved', '2026-01-25', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00153', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00416', 1, 'Identity', 'DOC-257165', '2026-01-20', 'Accepted', '2026-01-22', NULL),
('APP-2026-00416', 2, 'Registration', 'DOC-206196', '2026-01-20', 'Accepted', '2026-01-21', NULL),
('APP-2026-00416', 3, 'PriorPermit', 'PM-2025-00153', '2026-01-22', 'Accepted', '2026-01-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000409', 'APP-2026-00416', '2026-01-25', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00298', 'APP-2026-00416', '2026-01-26', '2026-01-26', '2027-01-25', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00417', 'AP-00134', 'GF-00145', '2026-01-21', 'Renewal', 'Approved', '2026-02-21', 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00056', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00417', 1, 'Identity', 'FILE-841673', '2026-01-21', 'Accepted', '2026-01-28', NULL),
('APP-2026-00417', 2, 'Registration', 'FILE-644522', '2026-01-23', 'Accepted', '2026-01-27', NULL),
('APP-2026-00417', 3, 'PriorPermit', 'PM-2025-00056', '2026-01-25', 'Accepted', '2026-01-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000410', 'APP-2026-00417', '2026-02-01', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00299', 'APP-2026-00417', '2026-02-22', '2026-02-22', '2027-02-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00418', 'AP-00137', 'GF-00158', '2026-01-22', 'Renewal', 'UnderReview', NULL, 'LC03', 'Mabini East', NULL, NULL, 'PM-2024-00017', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00418', 1, 'Identity', 'REF-16637', '2026-01-22', 'NeedsCorrection', '2026-01-28', 'Please provide the missing page of the supporting document.'),
('APP-2026-00418', 2, 'Registration', 'DOC-529360', '2026-01-26', 'NeedsCorrection', '2026-01-30', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00418', 3, 'PriorPermit', 'PM-2024-00017', '2026-01-27', 'Accepted', '2026-02-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000411', 'APP-2026-00418', '2026-01-25', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00419', 'AP-00021', 'GF-00101', '2026-01-23', 'New', 'Approved', '2026-01-28', 'LC03', 'Mabini East', 'ACQ-48655-26', '2025-10-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00419', 1, 'Identity', 'REF-480512', '2026-01-23', 'Accepted', '2026-01-26', NULL),
('APP-2026-00419', 2, 'Registration', 'REF-517566', '2026-01-23', 'Accepted', '2026-01-24', NULL),
('APP-2026-00419', 3, 'Acquisition', 'ACQ-48655-26', '2026-01-27', 'Accepted', '2026-01-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000412', 'APP-2026-00419', '2026-01-27', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00300', 'APP-2026-00419', '2026-01-30', '2026-01-30', '2027-01-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00420', 'AP-00020', 'GF-00133', '2026-01-23', 'New', 'Approved', '2026-01-31', 'LC03', 'Mabini East', 'ACQ-84875-26', '2025-11-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00420', 1, 'Identity', 'REF-237692', '2026-01-23', 'Accepted', '2026-01-28', NULL),
('APP-2026-00420', 2, 'Registration', 'FILE-994281', '2026-01-26', 'Accepted', '2026-01-28', NULL),
('APP-2026-00420', 3, 'Acquisition', 'ACQ-84875-26', '2026-01-25', 'Accepted', '2026-01-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000413', 'APP-2026-00420', '2026-01-27', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00301', 'APP-2026-00420', '2026-02-01', '2026-02-01', '2027-01-31', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00421', 'AP-00041', 'GF-00126', '2026-01-24', 'Renewal', 'Approved', '2026-02-13', 'LC05', 'Santa Elena', NULL, NULL, 'PM-2025-00115', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00421', 1, 'Identity', 'DOC-322771', '2026-01-24', 'Accepted', '2026-01-28', NULL),
('APP-2026-00421', 2, 'Registration', 'REF-984274', '2026-01-26', 'Accepted', '2026-02-02', NULL),
('APP-2026-00421', 3, 'PriorPermit', 'PM-2025-00115', '2026-01-29', 'Accepted', '2026-02-02', NULL),
('APP-2026-00421', 4, 'Other', 'DOC-767296', '2026-01-26', 'Accepted', '2026-01-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000414', 'APP-2026-00421', '2026-01-30', 900, 'BankTransfer'),
('OR-2026-000415', 'APP-2026-00421', '2026-01-24', 150, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00302', 'APP-2026-00421', '2026-02-18', '2026-02-18', '2027-02-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00422', 'AP-00004', 'GF-00082', '2026-01-25', 'New', 'Approved', '2026-01-28', 'LC01', 'Luntian Central', 'ACQ-56360-26', '2026-01-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00422', 1, 'Identity', 'REF-683620', '2026-01-25', 'Accepted', '2026-01-27', NULL),
('APP-2026-00422', 2, 'Registration', 'DOC-311995', '2026-01-26', 'Accepted', '2026-01-28', NULL),
('APP-2026-00422', 3, 'Acquisition', 'ACQ-56360-26', '2026-01-27', 'Accepted', '2026-01-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000416', 'APP-2026-00422', '2026-01-28', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00303', 'APP-2026-00422', '2026-01-28', '2026-01-28', '2027-01-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00423', 'AP-00094', 'GF-00024', '2026-01-27', 'New', 'Approved', '2026-02-21', 'LC03', 'Mabini East', 'ACQ-44755-26', '2025-12-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00423', 1, 'Identity', 'FILE-618478', '2026-01-27', 'Accepted', '2026-01-30', NULL),
('APP-2026-00423', 2, 'Registration', 'DOC-989188', '2026-02-01', 'Accepted', '2026-02-05', NULL),
('APP-2026-00423', 3, 'Acquisition', 'ACQ-44755-26', '2026-01-27', 'Accepted', '2026-01-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000417', 'APP-2026-00423', '2026-02-04', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00304', 'APP-2026-00423', '2026-02-22', '2026-02-22', '2027-02-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00424', 'AP-00056', 'GF-00138', '2026-01-28', 'New', 'Rejected', '2026-02-02', 'LC02', 'San Isidro Heights', 'ACQ-83499-26', '2025-10-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00424', 1, 'Identity', 'FILE-777190', '2026-01-28', 'Pending', NULL, NULL),
('APP-2026-00424', 2, 'Registration', 'DOC-246535', '2026-01-29', 'NeedsCorrection', '2026-01-30', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00424', 3, 'Acquisition', 'ACQ-83499-26', '2026-01-31', 'Accepted', '2026-02-02', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00425', 'AP-00032', 'GF-00048', '2026-01-28', 'Replacement', 'Rejected', '2026-02-19', 'LC08', 'San Rafael Norte', NULL, NULL, NULL, NULL, '2026-01-18', 'IR-2026-7711');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00425', 1, 'Identity', 'REF-951265', '2026-01-28', 'Pending', NULL, NULL),
('APP-2026-00425', 2, 'Registration', 'FILE-507810', '2026-01-29', 'Accepted', '2026-01-31', NULL),
('APP-2026-00425', 3, 'Incident', 'IR-2026-7711', '2026-01-30', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000418', 'APP-2026-00425', '2026-02-05', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00426', 'AP-00185', 'GF-00069', '2026-01-29', 'New', 'Approved', '2026-02-23', 'LC03', 'Mabini East', 'ACQ-62739-26', '2026-01-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00426', 1, 'Identity', 'DOC-140868', '2026-01-29', 'Accepted', '2026-02-01', NULL),
('APP-2026-00426', 2, 'Registration', 'FILE-922084', '2026-02-01', 'Accepted', '2026-02-08', NULL),
('APP-2026-00426', 3, 'Acquisition', 'ACQ-62739-26', '2026-02-03', 'Accepted', '2026-02-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000419', 'APP-2026-00426', '2026-02-02', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00305', 'APP-2026-00426', '2026-02-24', '2026-02-24', '2027-02-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00427', 'AP-00047', 'GF-00005', '2026-01-29', 'New', 'Approved', '2026-02-01', 'LC02', 'San Isidro Heights', 'ACQ-36031-26', '2025-11-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00427', 1, 'Identity', 'FILE-409298', '2026-01-29', 'Accepted', '2026-02-01', NULL),
('APP-2026-00427', 2, 'Registration', 'FILE-528311', '2026-01-30', 'Accepted', '2026-02-01', NULL),
('APP-2026-00427', 3, 'Acquisition', 'ACQ-36031-26', '2026-02-01', 'Accepted', '2026-02-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000420', 'APP-2026-00427', '2026-02-01', 350, 'BankTransfer'),
('OR-2026-000421', 'APP-2026-00427', '2026-02-01', 250, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00306', 'APP-2026-00427', '2026-02-03', '2026-02-03', '2027-02-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00428', 'AP-00114', 'GF-00124', '2026-01-29', 'New', 'Approved', '2026-02-06', 'LC01', 'Luntian Central', 'ACQ-67063-26', '2025-10-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00428', 1, 'Identity', 'FILE-642851', '2026-01-29', 'Accepted', '2026-02-01', NULL),
('APP-2026-00428', 2, 'Registration', 'REF-144605', '2026-01-30', 'Accepted', '2026-02-04', NULL),
('APP-2026-00428', 3, 'Acquisition', 'ACQ-67063-26', '2026-01-30', 'Accepted', '2026-02-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000422', 'APP-2026-00428', '2026-02-05', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00307', 'APP-2026-00428', '2026-02-08', '2026-02-08', '2027-02-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00429', 'AP-00118', 'GF-00009', '2026-01-29', 'Renewal', 'Approved', '2026-02-16', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00141', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00429', 1, 'Identity', 'REF-723275', '2026-01-29', 'Accepted', '2026-01-31', NULL),
('APP-2026-00429', 2, 'Registration', 'REF-990323', '2026-02-03', 'Accepted', '2026-02-08', NULL),
('APP-2026-00429', 3, 'PriorPermit', 'PM-2025-00141', '2026-01-31', 'Accepted', '2026-02-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000423', 'APP-2026-00429', '2026-01-30', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00308', 'APP-2026-00429', '2026-02-21', '2026-02-21', '2027-02-20', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00430', 'AP-00028', 'GF-00118', '2026-01-29', 'Renewal', 'Approved', '2026-02-21', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00131', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00430', 1, 'Identity', 'DOC-913045', '2026-01-29', 'Accepted', '2026-01-31', NULL),
('APP-2026-00430', 2, 'Registration', 'REF-751056', '2026-02-02', 'Accepted', '2026-02-04', NULL),
('APP-2026-00430', 3, 'PriorPermit', 'PM-2025-00131', '2026-01-31', 'Accepted', '2026-02-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000424', 'APP-2026-00430', '2026-01-30', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00309', 'APP-2026-00430', '2026-02-24', '2026-02-24', '2027-02-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00431', 'AP-00130', 'GF-00010', '2026-01-30', 'New', 'Approved', '2026-02-12', 'LC02', 'San Isidro Heights', 'ACQ-19174-26', '2025-10-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00431', 1, 'Identity', 'REF-950230', '2026-01-30', 'Accepted', '2026-02-01', NULL),
('APP-2026-00431', 2, 'Registration', 'FILE-766027', '2026-01-30', 'Accepted', '2026-02-05', NULL),
('APP-2026-00431', 3, 'Acquisition', 'ACQ-19174-26', '2026-01-30', 'Accepted', '2026-02-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000425', 'APP-2026-00431', '2026-02-05', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00310', 'APP-2026-00431', '2026-02-17', '2026-02-17', '2027-02-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00432', 'AP-00110', 'GF-00154', '2026-01-31', 'New', 'Approved', '2026-02-04', 'LC04', 'Bagong Silangan', 'ACQ-51566-26', '2025-10-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00432', 1, 'Identity', 'DOC-177389', '2026-01-31', 'Accepted', '2026-02-04', NULL),
('APP-2026-00432', 2, 'Registration', 'FILE-928957', '2026-01-31', 'Accepted', '2026-02-04', NULL),
('APP-2026-00432', 3, 'Acquisition', 'ACQ-51566-26', '2026-02-04', 'Accepted', '2026-02-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000426', 'APP-2026-00432', '2026-02-04', 900, 'Online'),
('OR-2026-000427', 'APP-2026-00432', '2026-02-04', 150, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00311', 'APP-2026-00432', '2026-02-07', '2026-02-07', '2027-02-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00433', 'AP-00032', 'GF-00126', '2026-01-31', 'New', 'Approved', '2026-02-17', 'LC08', 'San Rafael Norte', 'ACQ-78788-26', '2025-12-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00433', 1, 'Identity', 'REF-19497', '2026-01-31', 'Accepted', '2026-02-04', NULL),
('APP-2026-00433', 2, 'Registration', 'FILE-610364', '2026-02-04', 'Accepted', '2026-02-07', NULL),
('APP-2026-00433', 3, 'Acquisition', 'ACQ-78788-26', '2026-02-01', 'Accepted', '2026-02-03', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00312', 'APP-2026-00433', '2026-02-20', '2026-02-20', '2027-02-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00434', 'AP-00078', 'GF-00037', '2026-01-31', 'Renewal', 'Approved', '2026-02-14', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00064', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00434', 1, 'Identity', 'FILE-937324', '2026-01-31', 'Accepted', '2026-02-01', NULL),
('APP-2026-00434', 2, 'Registration', 'REF-900424', '2026-02-02', 'Accepted', '2026-02-09', NULL),
('APP-2026-00434', 3, 'PriorPermit', 'PM-2025-00064', '2026-02-03', 'Accepted', '2026-02-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000428', 'APP-2026-00434', '2026-02-02', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00313', 'APP-2026-00434', '2026-02-15', '2026-02-15', '2027-02-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00435', 'AP-00156', 'GF-00016', '2026-02-02', 'New', 'Approved', '2026-02-17', 'LC06', 'Maligaya', 'ACQ-34110-26', '2025-11-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00435', 1, 'Identity', 'DOC-544651', '2026-02-02', 'Accepted', '2026-02-06', NULL),
('APP-2026-00435', 2, 'Registration', 'FILE-232456', '2026-02-02', 'Accepted', '2026-02-09', NULL),
('APP-2026-00435', 3, 'Acquisition', 'ACQ-34110-26', '2026-02-04', 'Accepted', '2026-02-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000429', 'APP-2026-00435', '2026-02-10', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00314', 'APP-2026-00435', '2026-02-21', '2026-02-21', '2027-02-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00436', 'AP-00029', 'GF-00020', '2026-02-03', 'New', 'Rejected', '2026-02-27', 'LC02', 'San Isidro Heights', 'ACQ-38213-26', '2026-01-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00436', 1, 'Identity', 'REF-266904', '2026-02-03', 'Accepted', '2026-02-05', NULL),
('APP-2026-00436', 2, 'Registration', 'REF-324256', '2026-02-03', 'NeedsCorrection', '2026-02-09', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00436', 3, 'Acquisition', 'ACQ-38213-26', '2026-02-07', 'NeedsCorrection', '2026-02-14', 'Please provide the missing page of the supporting document.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000430', 'APP-2026-00436', '2026-02-15', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00437', 'AP-00159', 'GF-00131', '2026-02-03', 'Renewal', 'Approved', '2026-02-08', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2024-00003', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00437', 1, 'Identity', 'FILE-24907', '2026-02-03', 'Accepted', '2026-02-06', NULL),
('APP-2026-00437', 2, 'Registration', 'REF-258107', '2026-02-03', 'Accepted', '2026-02-08', NULL),
('APP-2026-00437', 3, 'PriorPermit', 'PM-2024-00003', '2026-02-07', 'Accepted', '2026-02-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000431', 'APP-2026-00437', '2026-02-08', 350, 'Online'),
('OR-2026-000432', 'APP-2026-00437', '2026-02-08', 150, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00438', 'AP-00051', 'GF-00044', '2026-02-04', 'New', 'Withdrawn', NULL, 'LC02', 'San Isidro Heights', 'ACQ-85690-26', '2025-10-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00438', 1, 'Identity', 'FILE-202891', '2026-02-04', 'NeedsCorrection', '2026-02-08', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00438', 2, 'Registration', 'DOC-244710', '2026-02-05', 'NeedsCorrection', '2026-02-07', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00438', 3, 'Acquisition', 'ACQ-85690-26', '2026-02-06', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000433', 'APP-2026-00438', '2026-02-14', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00439', 'AP-00020', 'GF-00094', '2026-02-05', 'New', 'Approved', '2026-02-21', 'LC03', 'Mabini East', 'ACQ-48414-26', '2025-12-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00439', 1, 'Identity', 'FILE-36735', '2026-02-05', 'Accepted', '2026-02-09', NULL),
('APP-2026-00439', 2, 'Registration', 'DOC-980793', '2026-02-06', 'Accepted', '2026-02-13', NULL),
('APP-2026-00439', 3, 'Acquisition', 'ACQ-48414-26', '2026-02-08', 'Accepted', '2026-02-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000434', 'APP-2026-00439', '2026-02-16', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00315', 'APP-2026-00439', '2026-02-22', '2026-02-22', '2027-02-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00440', 'AP-00075', 'GF-00024', '2026-02-06', 'New', 'Approved', '2026-02-16', 'LC01', 'Luntian Central', 'ACQ-56577-26', '2025-10-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00440', 1, 'Identity', 'DOC-614296', '2026-02-06', 'Accepted', '2026-02-07', NULL),
('APP-2026-00440', 2, 'Registration', 'REF-665490', '2026-02-08', 'Accepted', '2026-02-15', NULL),
('APP-2026-00440', 3, 'Acquisition', 'ACQ-56577-26', '2026-02-06', 'Accepted', '2026-02-12', NULL),
('APP-2026-00440', 4, 'Other', 'REF-642435', '2026-02-07', 'Accepted', '2026-02-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000435', 'APP-2026-00440', '2026-02-08', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00316', 'APP-2026-00440', '2026-02-19', '2026-02-19', '2027-02-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00441', 'AP-00034', 'GF-00009', '2026-02-09', 'New', 'Approved', '2026-02-19', 'LC04', 'Bagong Silangan', 'ACQ-55701-26', '2025-12-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00441', 1, 'Identity', 'FILE-662086', '2026-02-09', 'Accepted', '2026-02-14', NULL),
('APP-2026-00441', 2, 'Registration', 'DOC-882124', '2026-02-10', 'Accepted', '2026-02-13', NULL),
('APP-2026-00441', 3, 'Acquisition', 'ACQ-55701-26', '2026-02-11', 'Accepted', '2026-02-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000436', 'APP-2026-00441', '2026-02-09', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00317', 'APP-2026-00441', '2026-02-23', '2026-02-23', '2027-02-22', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00442', 'AP-00091', 'GF-00145', '2026-02-10', 'New', 'Approved', '2026-02-23', 'LC02', 'San Isidro Heights', 'ACQ-29197-26', '2025-12-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00442', 1, 'Identity', 'REF-414860', '2026-02-10', 'Accepted', '2026-02-13', NULL),
('APP-2026-00442', 2, 'Registration', 'FILE-622875', '2026-02-15', 'Accepted', '2026-02-21', NULL),
('APP-2026-00442', 3, 'Acquisition', 'ACQ-29197-26', '2026-02-13', 'Accepted', '2026-02-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000437', 'APP-2026-00442', '2026-02-11', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00443', 'AP-00082', 'GF-00081', '2026-02-10', 'Replacement', 'Approved', '2026-03-03', 'LC07', 'Pulo Verde', NULL, NULL, NULL, NULL, '2026-01-17', 'IR-2026-7101');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00443', 1, 'Identity', 'DOC-854084', '2026-02-10', 'Accepted', '2026-02-12', NULL),
('APP-2026-00443', 2, 'Registration', 'REF-498432', '2026-02-14', 'Accepted', '2026-02-17', NULL),
('APP-2026-00443', 3, 'Incident', 'IR-2026-7101', '2026-02-15', 'Accepted', '2026-02-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000438', 'APP-2026-00443', '2026-02-10', 450, 'Cash'),
('OR-2026-000439', 'APP-2026-00443', '2026-02-13', 250, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00318', 'APP-2026-00443', '2026-03-05', '2026-03-05', '2027-03-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00444', 'AP-00094', 'GF-00091', '2026-02-10', 'Replacement', 'UnderReview', NULL, 'LC03', 'Mabini East', NULL, NULL, NULL, NULL, '2026-02-04', 'IR-2026-5947');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00444', 1, 'Identity', 'FILE-855728', '2026-02-10', 'Accepted', '2026-02-14', NULL),
('APP-2026-00444', 2, 'Registration', 'FILE-736503', '2026-02-15', 'Pending', NULL, NULL),
('APP-2026-00444', 3, 'Incident', 'IR-2026-5947', '2026-02-10', 'NeedsCorrection', '2026-02-15', 'The recorded reference must be verified with the submitted copy.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000440', 'APP-2026-00444', '2026-02-14', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00445', 'AP-00070', 'GF-00145', '2026-02-11', 'New', 'Approved', '2026-02-17', 'LC05', 'Santa Elena', 'ACQ-68772-26', '2025-12-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00445', 1, 'Identity', 'REF-681548', '2026-02-11', 'Accepted', '2026-02-16', NULL),
('APP-2026-00445', 2, 'Registration', 'REF-386852', '2026-02-16', 'Accepted', '2026-02-17', NULL),
('APP-2026-00445', 3, 'Acquisition', 'ACQ-68772-26', '2026-02-12', 'Accepted', '2026-02-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000441', 'APP-2026-00445', '2026-02-17', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00319', 'APP-2026-00445', '2026-02-22', '2026-02-22', '2027-02-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00446', 'AP-00117', 'GF-00012', '2026-02-11', 'Renewal', 'Rejected', '2026-03-06', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00062', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00446', 1, 'Identity', 'FILE-938590', '2026-02-11', 'Accepted', '2026-02-13', NULL),
('APP-2026-00446', 2, 'Registration', 'DOC-41585', '2026-02-11', 'Pending', NULL, NULL),
('APP-2026-00446', 3, 'PriorPermit', 'PM-2025-00062', '2026-02-13', 'Accepted', '2026-02-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000442', 'APP-2026-00446', '2026-02-19', 1200, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00447', 'AP-00181', 'GF-00131', '2026-02-12', 'New', 'Approved', '2026-02-18', 'LC07', 'Pulo Verde', 'ACQ-78579-26', '2026-01-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00447', 1, 'Identity', 'REF-83617', '2026-02-12', 'Accepted', '2026-02-18', NULL),
('APP-2026-00447', 2, 'Registration', 'REF-849123', '2026-02-13', 'Accepted', '2026-02-18', NULL),
('APP-2026-00447', 3, 'Acquisition', 'ACQ-78579-26', '2026-02-17', 'Accepted', '2026-02-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000443', 'APP-2026-00447', '2026-02-16', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00320', 'APP-2026-00447', '2026-02-22', '2026-02-22', '2027-02-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00448', 'AP-00139', 'GF-00146', '2026-02-12', 'New', 'Approved', '2026-02-18', 'LC04', 'Bagong Silangan', 'ACQ-47985-26', '2026-01-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00448', 1, 'Identity', 'REF-387164', '2026-02-12', 'Accepted', '2026-02-18', NULL),
('APP-2026-00448', 2, 'Registration', 'DOC-910949', '2026-02-15', 'Accepted', '2026-02-18', NULL),
('APP-2026-00448', 3, 'Acquisition', 'ACQ-47985-26', '2026-02-16', 'Accepted', '2026-02-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000444', 'APP-2026-00448', '2026-02-18', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00321', 'APP-2026-00448', '2026-02-18', '2026-02-18', '2027-02-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00449', 'AP-00063', 'GF-00006', '2026-02-13', 'Renewal', 'Approved', '2026-03-30', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00061', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00449', 1, 'Identity', 'FILE-273085', '2026-02-13', 'Accepted', '2026-02-19', NULL),
('APP-2026-00449', 2, 'Registration', 'FILE-555302', '2026-02-13', 'Accepted', '2026-02-16', NULL),
('APP-2026-00449', 3, 'PriorPermit', 'PM-2025-00061', '2026-02-18', 'Accepted', '2026-02-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000445', 'APP-2026-00449', '2026-02-14', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00322', 'APP-2026-00449', '2026-04-04', '2026-04-04', '2027-04-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00450', 'AP-00062', 'GF-00029', '2026-02-13', 'Replacement', 'Approved', '2026-03-01', 'LC02', 'San Isidro Heights', NULL, NULL, NULL, NULL, '2026-02-01', 'IR-2026-6528');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00450', 1, 'Identity', 'FILE-116354', '2026-02-13', 'Accepted', '2026-02-17', NULL),
('APP-2026-00450', 2, 'Registration', 'REF-620573', '2026-02-18', 'Accepted', '2026-02-25', NULL),
('APP-2026-00450', 3, 'Incident', 'IR-2026-6528', '2026-02-17', 'Accepted', '2026-02-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000446', 'APP-2026-00450', '2026-02-19', 750, 'Cash'),
('OR-2026-000447', 'APP-2026-00450', '2026-02-17', 250, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00323', 'APP-2026-00450', '2026-03-01', '2026-03-01', '2027-02-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00451', 'AP-00009', 'GF-00142', '2026-02-14', 'New', 'Approved', '2026-02-19', 'LC02', 'San Isidro Heights', 'ACQ-78253-26', '2025-11-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00451', 1, 'Identity', 'REF-674335', '2026-02-14', 'Accepted', '2026-02-19', NULL),
('APP-2026-00451', 2, 'Registration', 'DOC-948065', '2026-02-16', 'Accepted', '2026-02-19', NULL),
('APP-2026-00451', 3, 'Acquisition', 'ACQ-78253-26', '2026-02-14', 'Accepted', '2026-02-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000448', 'APP-2026-00451', '2026-02-19', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00452', 'AP-00163', 'GF-00080', '2026-02-14', 'New', 'Approved', '2026-04-04', 'LC01', 'Luntian Central', 'ACQ-44075-26', '2025-11-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00452', 1, 'Identity', 'DOC-287354', '2026-02-14', 'Accepted', '2026-02-20', NULL),
('APP-2026-00452', 2, 'Registration', 'DOC-251048', '2026-02-14', 'Accepted', '2026-02-19', NULL),
('APP-2026-00452', 3, 'Acquisition', 'ACQ-44075-26', '2026-02-16', 'Accepted', '2026-02-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000449', 'APP-2026-00452', '2026-02-17', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00324', 'APP-2026-00452', '2026-04-06', '2026-04-06', '2027-04-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00453', 'AP-00174', 'GF-00024', '2026-02-15', 'New', 'Approved', '2026-02-24', 'LC03', 'Mabini East', 'ACQ-31906-26', '2025-12-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00453', 1, 'Identity', 'FILE-829130', '2026-02-15', 'Accepted', '2026-02-21', NULL),
('APP-2026-00453', 2, 'Registration', 'DOC-949878', '2026-02-15', 'Accepted', '2026-02-17', NULL),
('APP-2026-00453', 3, 'Acquisition', 'ACQ-31906-26', '2026-02-19', 'Accepted', '2026-02-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000450', 'APP-2026-00453', '2026-02-19', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00325', 'APP-2026-00453', '2026-02-26', '2026-02-26', '2027-02-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00454', 'AP-00085', 'GF-00147', '2026-02-15', 'New', 'Approved', '2026-02-24', 'LC03', 'Mabini East', 'ACQ-87840-26', '2025-10-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00454', 1, 'Identity', 'FILE-350847', '2026-02-15', 'Accepted', '2026-02-16', NULL),
('APP-2026-00454', 2, 'Registration', 'REF-840975', '2026-02-17', 'Accepted', '2026-02-24', NULL),
('APP-2026-00454', 3, 'Acquisition', 'ACQ-87840-26', '2026-02-20', 'Accepted', '2026-02-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000451', 'APP-2026-00454', '2026-02-24', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00326', 'APP-2026-00454', '2026-02-25', '2026-02-25', '2027-02-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00455', 'AP-00018', 'GF-00155', '2026-02-16', 'New', 'Submitted', NULL, 'LC05', 'Santa Elena', 'ACQ-85429-26', '2026-01-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00455', 1, 'Identity', 'DOC-285052', '2026-02-16', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00456', 'AP-00146', 'GF-00087', '2026-02-17', 'New', 'Withdrawn', NULL, 'LC01', 'Luntian Central', 'ACQ-46055-26', '2025-10-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00456', 1, 'Identity', 'REF-32408', '2026-02-17', 'NeedsCorrection', '2026-02-22', 'The date on the document needs clarification.'),
('APP-2026-00456', 2, 'Registration', 'FILE-509999', '2026-02-22', 'Accepted', '2026-02-24', NULL),
('APP-2026-00456', 3, 'Acquisition', 'ACQ-46055-26', '2026-02-18', 'Accepted', '2026-02-20', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00457', 'AP-00027', 'GF-00069', '2026-02-17', 'New', 'Approved', '2026-02-26', 'LC04', 'Bagong Silangan', 'ACQ-22840-26', '2026-01-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00457', 1, 'Identity', 'DOC-667783', '2026-02-17', 'Accepted', '2026-02-18', NULL),
('APP-2026-00457', 2, 'Registration', 'REF-575884', '2026-02-18', 'Accepted', '2026-02-22', NULL),
('APP-2026-00457', 3, 'Acquisition', 'ACQ-22840-26', '2026-02-18', 'Accepted', '2026-02-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000452', 'APP-2026-00457', '2026-02-25', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00327', 'APP-2026-00457', '2026-02-27', '2026-02-27', '2027-02-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00458', 'AP-00103', 'GF-00004', '2026-02-17', 'Renewal', 'Approved', '2026-03-10', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00128', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00458', 1, 'Identity', 'DOC-308696', '2026-02-17', 'Accepted', '2026-02-20', NULL),
('APP-2026-00458', 2, 'Registration', 'REF-99384', '2026-02-18', 'Accepted', '2026-02-20', NULL),
('APP-2026-00458', 3, 'PriorPermit', 'PM-2025-00128', '2026-02-20', 'Accepted', '2026-02-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000453', 'APP-2026-00458', '2026-02-24', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00328', 'APP-2026-00458', '2026-03-11', '2026-03-11', '2027-03-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00459', 'AP-00131', 'GF-00064', '2026-02-18', 'Renewal', 'Approved', '2026-02-27', 'LC05', 'Santa Elena', NULL, NULL, 'PM-2025-00024', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00459', 1, 'Identity', 'FILE-588771', '2026-02-18', 'Accepted', '2026-02-23', NULL),
('APP-2026-00459', 2, 'Registration', 'FILE-229239', '2026-02-21', 'Accepted', '2026-02-25', NULL),
('APP-2026-00459', 3, 'PriorPermit', 'PM-2025-00024', '2026-02-20', 'Accepted', '2026-02-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000454', 'APP-2026-00459', '2026-02-18', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00329', 'APP-2026-00459', '2026-03-01', '2026-03-01', '2027-02-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00460', 'AP-00111', 'GF-00120', '2026-02-19', 'New', 'Approved', '2026-03-21', 'LC05', 'Santa Elena', 'ACQ-86502-26', '2026-01-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00460', 1, 'Identity', 'FILE-916006', '2026-02-19', 'Accepted', '2026-02-24', NULL),
('APP-2026-00460', 2, 'Registration', 'REF-839457', '2026-02-23', 'Accepted', '2026-03-02', NULL),
('APP-2026-00460', 3, 'Acquisition', 'ACQ-86502-26', '2026-02-23', 'Accepted', '2026-03-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000455', 'APP-2026-00460', '2026-02-27', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00330', 'APP-2026-00460', '2026-03-26', '2026-03-26', '2027-03-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00461', 'AP-00169', 'GF-00143', '2026-02-21', 'New', 'Approved', '2026-03-06', 'LC03', 'Mabini East', 'ACQ-18065-26', '2025-11-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00461', 1, 'Identity', 'DOC-457859', '2026-02-21', 'Accepted', '2026-02-25', NULL),
('APP-2026-00461', 2, 'Registration', 'FILE-923442', '2026-02-23', 'Accepted', '2026-02-28', NULL),
('APP-2026-00461', 3, 'Acquisition', 'ACQ-18065-26', '2026-02-26', 'Accepted', '2026-03-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000456', 'APP-2026-00461', '2026-02-23', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00331', 'APP-2026-00461', '2026-03-10', '2026-03-10', '2027-03-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00462', 'AP-00157', 'GF-00112', '2026-02-21', 'New', 'Approved', '2026-03-01', 'LC03', 'Mabini East', 'ACQ-63427-26', '2025-11-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00462', 1, 'Identity', 'FILE-849240', '2026-02-21', 'Accepted', '2026-02-24', NULL),
('APP-2026-00462', 2, 'Registration', 'REF-79708', '2026-02-22', 'Accepted', '2026-02-27', NULL),
('APP-2026-00462', 3, 'Acquisition', 'ACQ-63427-26', '2026-02-25', 'Accepted', '2026-03-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000457', 'APP-2026-00462', '2026-02-26', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00332', 'APP-2026-00462', '2026-03-05', '2026-03-05', '2027-03-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00463', 'AP-00100', 'GF-00035', '2026-02-22', 'New', 'Approved', '2026-03-15', 'LC04', 'Bagong Silangan', 'ACQ-94272-26', '2026-01-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00463', 1, 'Identity', 'FILE-258779', '2026-02-22', 'Accepted', '2026-02-26', NULL),
('APP-2026-00463', 2, 'Registration', 'REF-83420', '2026-02-26', 'Accepted', '2026-03-04', NULL),
('APP-2026-00463', 3, 'Acquisition', 'ACQ-94272-26', '2026-02-23', 'Accepted', '2026-02-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000458', 'APP-2026-00463', '2026-02-28', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00333', 'APP-2026-00463', '2026-03-19', '2026-03-19', '2027-03-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00464', 'AP-00087', 'GF-00030', '2026-02-23', 'New', 'Approved', '2026-03-08', 'LC03', 'Mabini East', 'ACQ-77964-26', '2025-11-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00464', 1, 'Identity', 'DOC-191697', '2026-02-23', 'Accepted', '2026-02-25', NULL),
('APP-2026-00464', 2, 'Registration', 'FILE-605691', '2026-02-25', 'Accepted', '2026-03-03', NULL),
('APP-2026-00464', 3, 'Acquisition', 'ACQ-77964-26', '2026-02-25', 'Accepted', '2026-03-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000459', 'APP-2026-00464', '2026-03-05', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00334', 'APP-2026-00464', '2026-03-10', '2026-03-10', '2027-03-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00465', 'AP-00178', 'GF-00022', '2026-02-24', 'New', 'Approved', '2026-03-21', 'LC02', 'San Isidro Heights', 'ACQ-76948-26', '2025-12-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00465', 1, 'Identity', 'REF-814036', '2026-02-24', 'Accepted', '2026-03-02', NULL),
('APP-2026-00465', 2, 'Registration', 'FILE-531295', '2026-02-26', 'Accepted', '2026-03-02', NULL),
('APP-2026-00465', 3, 'Acquisition', 'ACQ-76948-26', '2026-02-25', 'Accepted', '2026-03-01', NULL),
('APP-2026-00465', 4, 'Other', 'REF-847436', '2026-03-01', 'Accepted', '2026-03-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000460', 'APP-2026-00465', '2026-03-04', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00335', 'APP-2026-00465', '2026-03-26', '2026-03-26', '2027-03-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00466', 'AP-00026', 'GF-00026', '2026-02-25', 'New', 'Approved', '2026-03-17', 'LC03', 'Mabini East', 'ACQ-53768-26', '2026-01-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00466', 1, 'Identity', 'DOC-73931', '2026-02-25', 'Accepted', '2026-02-26', NULL),
('APP-2026-00466', 2, 'Registration', 'REF-672437', '2026-03-01', 'Accepted', '2026-03-07', NULL),
('APP-2026-00466', 3, 'Acquisition', 'ACQ-53768-26', '2026-03-02', 'Accepted', '2026-03-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000461', 'APP-2026-00466', '2026-02-27', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00336', 'APP-2026-00466', '2026-03-17', '2026-03-17', '2027-03-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00467', 'AP-00144', 'GF-00041', '2026-02-25', 'New', 'Submitted', NULL, 'LC02', 'San Isidro Heights', 'ACQ-83776-26', '2026-02-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00467', 1, 'Identity', 'DOC-314113', '2026-02-25', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000462', 'APP-2026-00467', '2026-03-04', 1200, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00468', 'AP-00180', 'GF-00062', '2026-02-25', 'Replacement', 'Approved', '2026-03-10', 'LC07', 'Pulo Verde', NULL, NULL, NULL, NULL, '2026-02-17', 'IR-2026-3661');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00468', 1, 'Identity', 'REF-84732', '2026-02-25', 'Accepted', '2026-02-28', NULL),
('APP-2026-00468', 2, 'Registration', 'REF-564831', '2026-03-02', 'Accepted', '2026-03-03', NULL),
('APP-2026-00468', 3, 'Incident', 'IR-2026-3661', '2026-03-02', 'Accepted', '2026-03-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000463', 'APP-2026-00468', '2026-03-01', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00337', 'APP-2026-00468', '2026-03-11', '2026-03-11', '2027-03-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00469', 'AP-00168', 'GF-00120', '2026-02-26', 'New', 'Approved', '2026-03-21', 'LC01', 'Luntian Central', 'ACQ-49180-26', '2025-10-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00469', 1, 'Identity', 'REF-582916', '2026-02-26', 'Accepted', '2026-03-04', NULL),
('APP-2026-00469', 2, 'Registration', 'DOC-724784', '2026-02-27', 'Accepted', '2026-02-28', NULL),
('APP-2026-00469', 3, 'Acquisition', 'ACQ-49180-26', '2026-02-28', 'Accepted', '2026-03-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000464', 'APP-2026-00469', '2026-03-01', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00338', 'APP-2026-00469', '2026-03-24', '2026-03-24', '2027-03-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00470', 'AP-00069', 'GF-00139', '2026-02-27', 'Renewal', 'Approved', '2026-03-21', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00073', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00470', 1, 'Identity', 'DOC-764983', '2026-02-27', 'Accepted', '2026-03-02', NULL),
('APP-2026-00470', 2, 'Registration', 'REF-815030', '2026-03-03', 'Accepted', '2026-03-05', NULL),
('APP-2026-00470', 3, 'PriorPermit', 'PM-2025-00073', '2026-03-04', 'Accepted', '2026-03-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000465', 'APP-2026-00470', '2026-03-01', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00339', 'APP-2026-00470', '2026-03-26', '2026-03-26', '2027-03-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00471', 'AP-00089', 'GF-00118', '2026-02-28', 'New', 'Approved', '2026-03-10', 'LC01', 'Luntian Central', 'ACQ-25693-26', '2025-12-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00471', 1, 'Identity', 'FILE-938348', '2026-02-28', 'Accepted', '2026-03-06', NULL),
('APP-2026-00471', 2, 'Registration', 'REF-435511', '2026-03-05', 'Accepted', '2026-03-07', NULL),
('APP-2026-00471', 3, 'Acquisition', 'ACQ-25693-26', '2026-03-03', 'Accepted', '2026-03-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000466', 'APP-2026-00471', '2026-03-10', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00340', 'APP-2026-00471', '2026-03-10', '2026-03-10', '2027-03-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00472', 'AP-00057', 'GF-00128', '2026-03-01', 'New', 'Approved', '2026-03-10', 'LC03', 'Mabini East', 'ACQ-22440-26', '2026-01-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00472', 1, 'Identity', 'DOC-649305', '2026-03-01', 'Accepted', '2026-03-08', NULL),
('APP-2026-00472', 2, 'Registration', 'DOC-836535', '2026-03-05', 'Accepted', '2026-03-08', NULL),
('APP-2026-00472', 3, 'Acquisition', 'ACQ-22440-26', '2026-03-05', 'Accepted', '2026-03-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000467', 'APP-2026-00472', '2026-03-07', 450, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00473', 'AP-00169', 'GF-00076', '2026-03-02', 'New', 'Approved', '2026-03-15', 'LC03', 'Mabini East', 'ACQ-73014-26', '2025-11-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00473', 1, 'Identity', 'DOC-783594', '2026-03-02', 'Accepted', '2026-03-06', NULL),
('APP-2026-00473', 2, 'Registration', 'REF-704744', '2026-03-05', 'Accepted', '2026-03-10', NULL),
('APP-2026-00473', 3, 'Acquisition', 'ACQ-73014-26', '2026-03-04', 'Accepted', '2026-03-09', NULL),
('APP-2026-00473', 4, 'Other', 'FILE-429574', '2026-03-05', 'Accepted', '2026-03-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000468', 'APP-2026-00473', '2026-03-14', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00341', 'APP-2026-00473', '2026-03-15', '2026-03-15', '2027-03-14', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00474', 'AP-00101', 'GF-00139', '2026-03-02', 'New', 'Approved', '2026-03-15', 'LC08', 'San Rafael Norte', 'ACQ-84470-26', '2026-02-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00474', 1, 'Identity', 'FILE-194109', '2026-03-02', 'Accepted', '2026-03-03', NULL),
('APP-2026-00474', 2, 'Registration', 'REF-902462', '2026-03-05', 'Accepted', '2026-03-11', NULL),
('APP-2026-00474', 3, 'Acquisition', 'ACQ-84470-26', '2026-03-03', 'Accepted', '2026-03-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000469', 'APP-2026-00474', '2026-03-10', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00342', 'APP-2026-00474', '2026-03-15', '2026-03-15', '2027-03-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00475', 'AP-00082', 'GF-00081', '2026-03-02', 'Replacement', 'Rejected', '2026-03-05', 'LC07', 'Pulo Verde', NULL, NULL, NULL, NULL, '2026-02-14', 'IR-2026-8233');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00475', 1, 'Identity', 'REF-100920', '2026-03-02', 'NeedsCorrection', '2026-03-05', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00475', 2, 'Registration', 'FILE-635846', '2026-03-05', 'Accepted', '2026-03-05', NULL),
('APP-2026-00475', 3, 'Incident', 'IR-2026-8233', '2026-03-02', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00476', 'AP-00066', 'GF-00024', '2026-03-03', 'New', 'Approved', '2026-03-11', 'LC04', 'Bagong Silangan', 'ACQ-92597-26', '2025-12-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00476', 1, 'Identity', 'REF-671708', '2026-03-03', 'Accepted', '2026-03-08', NULL),
('APP-2026-00476', 2, 'Registration', 'REF-250110', '2026-03-04', 'Accepted', '2026-03-09', NULL),
('APP-2026-00476', 3, 'Acquisition', 'ACQ-92597-26', '2026-03-03', 'Accepted', '2026-03-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000470', 'APP-2026-00476', '2026-03-07', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00343', 'APP-2026-00476', '2026-03-15', '2026-03-15', '2027-03-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00477', 'AP-00151', 'GF-00093', '2026-03-04', 'New', 'UnderReview', NULL, 'LC06', 'Maligaya', 'ACQ-98409-26', '2025-12-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00477', 1, 'Identity', 'REF-239524', '2026-03-04', 'NeedsCorrection', '2026-03-05', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00477', 2, 'Registration', 'DOC-87049', '2026-03-07', 'Accepted', '2026-03-10', NULL),
('APP-2026-00477', 3, 'Acquisition', 'ACQ-98409-26', '2026-03-04', 'NeedsCorrection', '2026-03-10', 'A clearer copy of the reference portion is requested.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000471', 'APP-2026-00477', '2026-03-10', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00478', 'AP-00003', 'GF-00108', '2026-03-04', 'New', 'Approved', '2026-03-27', 'LC05', 'Santa Elena', 'ACQ-27513-26', '2025-12-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00478', 1, 'Identity', 'DOC-573173', '2026-03-04', 'Accepted', '2026-03-06', NULL),
('APP-2026-00478', 2, 'Registration', 'DOC-93320', '2026-03-04', 'Accepted', '2026-03-08', NULL),
('APP-2026-00478', 3, 'Acquisition', 'ACQ-27513-26', '2026-03-08', 'Accepted', '2026-03-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000472', 'APP-2026-00478', '2026-03-04', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00344', 'APP-2026-00478', '2026-03-30', '2026-03-30', '2027-03-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00479', 'AP-00079', 'GF-00092', '2026-03-05', 'New', 'Approved', '2026-03-28', 'LC05', 'Santa Elena', 'ACQ-21548-26', '2025-11-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00479', 1, 'Identity', 'FILE-368825', '2026-03-05', 'Accepted', '2026-03-07', NULL),
('APP-2026-00479', 2, 'Registration', 'FILE-770943', '2026-03-07', 'Accepted', '2026-03-11', NULL),
('APP-2026-00479', 3, 'Acquisition', 'ACQ-21548-26', '2026-03-07', 'Accepted', '2026-03-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000473', 'APP-2026-00479', '2026-03-14', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00345', 'APP-2026-00479', '2026-03-29', '2026-03-29', '2027-03-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00480', 'AP-00103', 'GF-00047', '2026-03-06', 'New', 'Approved', '2026-03-30', 'LC05', 'Santa Elena', 'ACQ-83305-26', '2025-12-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00480', 1, 'Identity', 'REF-906044', '2026-03-06', 'Accepted', '2026-03-11', NULL),
('APP-2026-00480', 2, 'Registration', 'FILE-242675', '2026-03-11', 'Accepted', '2026-03-16', NULL),
('APP-2026-00480', 3, 'Acquisition', 'ACQ-83305-26', '2026-03-11', 'Accepted', '2026-03-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000474', 'APP-2026-00480', '2026-03-08', 1200, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00481', 'AP-00016', 'GF-00164', '2026-03-06', 'New', 'UnderReview', NULL, 'LC06', 'Maligaya', 'ACQ-92766-26', '2025-12-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00481', 1, 'Identity', 'DOC-303932', '2026-03-06', 'Accepted', '2026-03-07', NULL),
('APP-2026-00481', 2, 'Registration', 'DOC-402798', '2026-03-09', 'Accepted', '2026-03-15', NULL),
('APP-2026-00481', 3, 'Acquisition', 'ACQ-92766-26', '2026-03-08', 'Accepted', '2026-03-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000475', 'APP-2026-00481', '2026-03-09', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00482', 'AP-00028', 'GF-00132', '2026-03-07', 'New', 'Approved', '2026-03-25', 'LC01', 'Luntian Central', 'ACQ-84034-26', '2026-02-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00482', 1, 'Identity', 'FILE-175933', '2026-03-07', 'Accepted', '2026-03-12', NULL),
('APP-2026-00482', 2, 'Registration', 'REF-132639', '2026-03-10', 'Accepted', '2026-03-16', NULL),
('APP-2026-00482', 3, 'Acquisition', 'ACQ-84034-26', '2026-03-08', 'Accepted', '2026-03-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000476', 'APP-2026-00482', '2026-03-19', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00483', 'AP-00006', 'GF-00019', '2026-03-07', 'New', 'Approved', '2026-03-20', 'LC03', 'Mabini East', 'ACQ-65735-26', '2026-02-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00483', 1, 'Identity', 'FILE-654359', '2026-03-07', 'Accepted', '2026-03-13', NULL),
('APP-2026-00483', 2, 'Registration', 'REF-695454', '2026-03-11', 'Accepted', '2026-03-14', NULL),
('APP-2026-00483', 3, 'Acquisition', 'ACQ-65735-26', '2026-03-12', 'Accepted', '2026-03-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000477', 'APP-2026-00483', '2026-03-19', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00346', 'APP-2026-00483', '2026-03-20', '2026-03-20', '2027-03-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00484', 'AP-00119', 'GF-00127', '2026-03-08', 'New', 'Approved', '2026-03-13', 'LC01', 'Luntian Central', 'ACQ-86386-26', '2025-12-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00484', 1, 'Identity', 'FILE-388308', '2026-03-08', 'Accepted', '2026-03-09', NULL),
('APP-2026-00484', 2, 'Registration', 'DOC-413467', '2026-03-11', 'Accepted', '2026-03-13', NULL),
('APP-2026-00484', 3, 'Acquisition', 'ACQ-86386-26', '2026-03-13', 'Accepted', '2026-03-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000478', 'APP-2026-00484', '2026-03-11', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00347', 'APP-2026-00484', '2026-03-13', '2026-03-13', '2027-03-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00485', 'AP-00075', 'GF-00080', '2026-03-08', 'New', 'Approved', '2026-03-15', 'LC01', 'Luntian Central', 'ACQ-99962-26', '2025-12-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00485', 1, 'Identity', 'REF-11381', '2026-03-08', 'Accepted', '2026-03-10', NULL),
('APP-2026-00485', 2, 'Registration', 'DOC-941636', '2026-03-13', 'Accepted', '2026-03-15', NULL),
('APP-2026-00485', 3, 'Acquisition', 'ACQ-99962-26', '2026-03-08', 'Accepted', '2026-03-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000479', 'APP-2026-00485', '2026-03-09', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00348', 'APP-2026-00485', '2026-03-17', '2026-03-17', '2027-03-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00486', 'AP-00024', 'GF-00007', '2026-03-08', 'New', 'Approved', '2026-03-23', 'LC07', 'Pulo Verde', 'ACQ-39832-26', '2026-01-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00486', 1, 'Identity', 'REF-813621', '2026-03-08', 'Accepted', '2026-03-15', NULL),
('APP-2026-00486', 2, 'Registration', 'FILE-909170', '2026-03-08', 'Accepted', '2026-03-12', NULL),
('APP-2026-00486', 3, 'Acquisition', 'ACQ-39832-26', '2026-03-11', 'Accepted', '2026-03-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000480', 'APP-2026-00486', '2026-03-14', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00349', 'APP-2026-00486', '2026-03-28', '2026-03-28', '2027-03-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00487', 'AP-00166', 'GF-00064', '2026-03-10', 'New', 'Approved', '2026-03-19', 'LC05', 'Santa Elena', 'ACQ-65280-26', '2025-11-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00487', 1, 'Identity', 'FILE-177900', '2026-03-10', 'Accepted', '2026-03-17', NULL),
('APP-2026-00487', 2, 'Registration', 'FILE-243426', '2026-03-15', 'Accepted', '2026-03-18', NULL),
('APP-2026-00487', 3, 'Acquisition', 'ACQ-65280-26', '2026-03-10', 'Accepted', '2026-03-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000481', 'APP-2026-00487', '2026-03-16', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00350', 'APP-2026-00487', '2026-03-24', '2026-03-24', '2027-03-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00488', 'AP-00055', 'GF-00126', '2026-03-10', 'Replacement', 'Approved', '2026-03-13', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2026-03-07', 'IR-2026-1967');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00488', 1, 'Identity', 'DOC-644041', '2026-03-10', 'Accepted', '2026-03-13', NULL),
('APP-2026-00488', 2, 'Registration', 'DOC-472098', '2026-03-10', 'Accepted', '2026-03-13', NULL),
('APP-2026-00488', 3, 'Incident', 'IR-2026-1967', '2026-03-13', 'Accepted', '2026-03-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000482', 'APP-2026-00488', '2026-03-12', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00351', 'APP-2026-00488', '2026-03-16', '2026-03-16', '2027-03-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00489', 'AP-00062', 'GF-00029', '2026-03-11', 'Renewal', 'Approved', '2026-04-28', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00089', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00489', 1, 'Identity', 'FILE-513307', '2026-03-11', 'Accepted', '2026-03-12', NULL),
('APP-2026-00489', 2, 'Registration', 'FILE-143069', '2026-03-16', 'Accepted', '2026-03-19', NULL),
('APP-2026-00489', 3, 'PriorPermit', 'PM-2025-00089', '2026-03-11', 'Accepted', '2026-03-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000483', 'APP-2026-00489', '2026-03-21', 450, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00352', 'APP-2026-00489', '2026-04-28', '2026-04-28', '2027-04-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00490', 'AP-00127', 'GF-00014', '2026-03-13', 'New', 'Approved', '2026-04-04', 'LC01', 'Luntian Central', 'ACQ-64834-26', '2026-02-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00490', 1, 'Identity', 'REF-243398', '2026-03-13', 'Accepted', '2026-03-20', NULL),
('APP-2026-00490', 2, 'Registration', 'DOC-585936', '2026-03-17', 'Accepted', '2026-03-23', NULL),
('APP-2026-00490', 3, 'Acquisition', 'ACQ-64834-26', '2026-03-16', 'Accepted', '2026-03-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000484', 'APP-2026-00490', '2026-03-22', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00353', 'APP-2026-00490', '2026-04-06', '2026-04-06', '2027-04-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00491', 'AP-00135', 'GF-00060', '2026-03-13', 'New', 'Approved', '2026-03-29', 'LC01', 'Luntian Central', 'ACQ-49508-26', '2025-11-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00491', 1, 'Identity', 'DOC-101007', '2026-03-13', 'Accepted', '2026-03-17', NULL),
('APP-2026-00491', 2, 'Registration', 'DOC-235348', '2026-03-18', 'Accepted', '2026-03-21', NULL),
('APP-2026-00491', 3, 'Acquisition', 'ACQ-49508-26', '2026-03-16', 'Accepted', '2026-03-19', NULL),
('APP-2026-00491', 4, 'Other', 'REF-955390', '2026-03-15', 'Accepted', '2026-03-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000485', 'APP-2026-00491', '2026-03-24', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00354', 'APP-2026-00491', '2026-04-02', '2026-04-02', '2027-04-01', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00492', 'AP-00057', 'GF-00011', '2026-03-14', 'Renewal', 'Approved', '2026-04-01', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00127', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00492', 1, 'Identity', 'REF-802873', '2026-03-14', 'Accepted', '2026-03-19', NULL),
('APP-2026-00492', 2, 'Registration', 'FILE-42533', '2026-03-18', 'Accepted', '2026-03-23', NULL),
('APP-2026-00492', 3, 'PriorPermit', 'PM-2025-00127', '2026-03-19', 'Accepted', '2026-03-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000486', 'APP-2026-00492', '2026-03-23', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00355', 'APP-2026-00492', '2026-04-06', '2026-04-06', '2027-04-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00493', 'AP-00077', 'GF-00066', '2026-03-15', 'New', 'Approved', '2026-04-21', 'LC05', 'Santa Elena', 'ACQ-75051-26', '2026-02-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00493', 1, 'Identity', 'REF-780161', '2026-03-15', 'Accepted', '2026-03-19', NULL),
('APP-2026-00493', 2, 'Registration', 'FILE-795315', '2026-03-18', 'Accepted', '2026-03-25', NULL),
('APP-2026-00493', 3, 'Acquisition', 'ACQ-75051-26', '2026-03-18', 'Accepted', '2026-03-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000487', 'APP-2026-00493', '2026-03-26', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00356', 'APP-2026-00493', '2026-04-25', '2026-04-25', '2027-04-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00494', 'AP-00029', 'GF-00123', '2026-03-15', 'New', 'Approved', '2026-03-30', 'LC02', 'San Isidro Heights', 'ACQ-85716-26', '2025-12-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00494', 1, 'Identity', 'FILE-515675', '2026-03-15', 'Accepted', '2026-03-19', NULL),
('APP-2026-00494', 2, 'Registration', 'REF-730051', '2026-03-20', 'Accepted', '2026-03-24', NULL),
('APP-2026-00494', 3, 'Acquisition', 'ACQ-85716-26', '2026-03-15', 'Accepted', '2026-03-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000488', 'APP-2026-00494', '2026-03-22', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00357', 'APP-2026-00494', '2026-03-30', '2026-03-30', '2027-03-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00495', 'AP-00124', 'GF-00008', '2026-03-15', 'Renewal', 'Approved', '2026-03-25', 'LC06', 'Maligaya', NULL, NULL, 'PM-2025-00138', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00495', 1, 'Identity', 'FILE-870691', '2026-03-15', 'Accepted', '2026-03-19', NULL),
('APP-2026-00495', 2, 'Registration', 'DOC-565843', '2026-03-17', 'Accepted', '2026-03-20', NULL),
('APP-2026-00495', 3, 'PriorPermit', 'PM-2025-00138', '2026-03-20', 'Accepted', '2026-03-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000489', 'APP-2026-00495', '2026-03-18', 350, 'BankTransfer'),
('OR-2026-000490', 'APP-2026-00495', '2026-03-22', 200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00358', 'APP-2026-00495', '2026-03-29', '2026-03-29', '2027-03-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00496', 'AP-00044', 'GF-00031', '2026-03-17', 'Renewal', 'Approved', '2026-03-27', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00049', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00496', 1, 'Identity', 'DOC-757188', '2026-03-17', 'Accepted', '2026-03-20', NULL),
('APP-2026-00496', 2, 'Registration', 'FILE-565134', '2026-03-20', 'Accepted', '2026-03-24', NULL),
('APP-2026-00496', 3, 'PriorPermit', 'PM-2025-00049', '2026-03-17', 'Accepted', '2026-03-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000491', 'APP-2026-00496', '2026-03-27', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00359', 'APP-2026-00496', '2026-03-31', '2026-03-31', '2027-03-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00497', 'AP-00150', 'GF-00152', '2026-03-19', 'New', 'Approved', '2026-03-28', 'LC06', 'Maligaya', 'ACQ-65684-26', '2025-12-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00497', 1, 'Identity', 'REF-283161', '2026-03-19', 'Accepted', '2026-03-25', NULL),
('APP-2026-00497', 2, 'Registration', 'REF-82496', '2026-03-22', 'Accepted', '2026-03-28', NULL),
('APP-2026-00497', 3, 'Acquisition', 'ACQ-65684-26', '2026-03-24', 'Accepted', '2026-03-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000492', 'APP-2026-00497', '2026-03-19', 900, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00498', 'AP-00106', 'GF-00161', '2026-03-21', 'New', 'Approved', '2026-04-15', 'LC05', 'Santa Elena', 'ACQ-28127-26', '2026-01-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00498', 1, 'Identity', 'FILE-981977', '2026-03-21', 'Accepted', '2026-03-28', NULL),
('APP-2026-00498', 2, 'Registration', 'FILE-990280', '2026-03-23', 'Accepted', '2026-03-27', NULL),
('APP-2026-00498', 3, 'Acquisition', 'ACQ-28127-26', '2026-03-24', 'Accepted', '2026-03-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000493', 'APP-2026-00498', '2026-03-26', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00360', 'APP-2026-00498', '2026-04-17', '2026-04-17', '2027-04-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00499', 'AP-00134', 'GF-00073', '2026-03-23', 'New', 'Rejected', '2026-04-01', 'LC07', 'Pulo Verde', 'ACQ-41461-26', '2025-12-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00499', 1, 'Identity', 'REF-747237', '2026-03-23', 'NeedsCorrection', '2026-03-30', 'The date on the document needs clarification.'),
('APP-2026-00499', 2, 'Registration', 'DOC-367957', '2026-03-24', 'NeedsCorrection', '2026-03-31', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00499', 3, 'Acquisition', 'ACQ-41461-26', '2026-03-25', 'NeedsCorrection', '2026-03-27', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00499', 4, 'Other', 'DOC-872364', '2026-03-28', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000494', 'APP-2026-00499', '2026-04-01', 1200, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00500', 'AP-00099', 'GF-00165', '2026-03-24', 'Renewal', 'Approved', '2026-03-27', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00139', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00500', 1, 'Identity', 'DOC-205874', '2026-03-24', 'Accepted', '2026-03-27', NULL),
('APP-2026-00500', 2, 'Registration', 'DOC-101841', '2026-03-25', 'Accepted', '2026-03-27', NULL),
('APP-2026-00500', 3, 'PriorPermit', 'PM-2025-00139', '2026-03-27', 'Accepted', '2026-03-27', NULL),
('APP-2026-00500', 4, 'Other', 'FILE-29010', '2026-03-25', 'Accepted', '2026-03-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000495', 'APP-2026-00500', '2026-03-27', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00361', 'APP-2026-00500', '2026-04-01', '2026-04-01', '2027-03-31', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00501', 'AP-00156', 'GF-00073', '2026-03-25', 'New', 'Approved', '2026-04-11', 'LC06', 'Maligaya', 'ACQ-31997-26', '2026-03-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00501', 1, 'Identity', 'REF-358791', '2026-03-25', 'Accepted', '2026-03-26', NULL),
('APP-2026-00501', 2, 'Registration', 'FILE-242155', '2026-03-29', 'Accepted', '2026-04-05', NULL),
('APP-2026-00501', 3, 'Acquisition', 'ACQ-31997-26', '2026-03-29', 'Accepted', '2026-04-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000496', 'APP-2026-00501', '2026-03-25', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00362', 'APP-2026-00501', '2026-04-15', '2026-04-15', '2027-04-14', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00502', 'AP-00176', 'GF-00067', '2026-03-26', 'New', 'Approved', '2026-03-31', 'LC04', 'Bagong Silangan', 'ACQ-45094-26', '2026-03-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00502', 1, 'Identity', 'DOC-553793', '2026-03-26', 'Accepted', '2026-03-28', NULL),
('APP-2026-00502', 2, 'Registration', 'FILE-874907', '2026-03-26', 'Accepted', '2026-03-30', NULL),
('APP-2026-00502', 3, 'Acquisition', 'ACQ-45094-26', '2026-03-27', 'Accepted', '2026-03-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000497', 'APP-2026-00502', '2026-03-30', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00363', 'APP-2026-00502', '2026-03-31', '2026-03-31', '2027-03-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00503', 'AP-00002', 'GF-00087', '2026-03-29', 'New', 'Withdrawn', NULL, 'LC07', 'Pulo Verde', 'ACQ-84909-26', '2026-01-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00503', 1, 'Identity', 'REF-342952', '2026-03-29', 'Pending', NULL, NULL),
('APP-2026-00503', 2, 'Registration', 'REF-705299', '2026-03-31', 'Pending', NULL, NULL),
('APP-2026-00503', 3, 'Acquisition', 'ACQ-84909-26', '2026-04-03', 'Accepted', '2026-04-04', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00504', 'AP-00095', 'GF-00056', '2026-03-30', 'New', 'Approved', '2026-04-24', 'LC03', 'Mabini East', 'ACQ-63528-26', '2025-12-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00504', 1, 'Identity', 'FILE-169558', '2026-03-30', 'Accepted', '2026-04-06', NULL),
('APP-2026-00504', 2, 'Registration', 'FILE-743583', '2026-04-02', 'Accepted', '2026-04-06', NULL),
('APP-2026-00504', 3, 'Acquisition', 'ACQ-63528-26', '2026-03-30', 'Accepted', '2026-04-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000498', 'APP-2026-00504', '2026-04-06', 600, 'Online'),
('OR-2026-000499', 'APP-2026-00504', '2026-04-03', 250, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00364', 'APP-2026-00504', '2026-04-27', '2026-04-27', '2027-04-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00505', 'AP-00167', 'GF-00056', '2026-03-30', 'Replacement', 'Approved', '2026-04-24', 'LC02', 'San Isidro Heights', NULL, NULL, NULL, NULL, '2026-03-15', 'IR-2026-4121');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00505', 1, 'Identity', 'REF-349069', '2026-03-30', 'Accepted', '2026-04-03', NULL),
('APP-2026-00505', 2, 'Registration', 'REF-647936', '2026-04-01', 'Accepted', '2026-04-06', NULL),
('APP-2026-00505', 3, 'Incident', 'IR-2026-4121', '2026-03-30', 'Accepted', '2026-04-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000500', 'APP-2026-00505', '2026-03-30', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00365', 'APP-2026-00505', '2026-04-25', '2026-04-25', '2027-04-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00506', 'AP-00032', 'GF-00061', '2026-03-31', 'New', 'Approved', '2026-04-20', 'LC08', 'San Rafael Norte', 'ACQ-68480-26', '2025-12-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00506', 1, 'Identity', 'DOC-333362', '2026-03-31', 'Accepted', '2026-04-02', NULL),
('APP-2026-00506', 2, 'Registration', 'DOC-416773', '2026-04-03', 'Accepted', '2026-04-05', NULL),
('APP-2026-00506', 3, 'Acquisition', 'ACQ-68480-26', '2026-04-05', 'Accepted', '2026-04-08', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00366', 'APP-2026-00506', '2026-04-25', '2026-04-25', '2027-04-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00507', 'AP-00005', 'GF-00011', '2026-03-31', 'New', 'Approved', '2026-05-29', 'LC03', 'Mabini East', 'ACQ-10517-26', '2026-03-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00507', 1, 'Identity', 'FILE-619715', '2026-03-31', 'Accepted', '2026-04-03', NULL),
('APP-2026-00507', 2, 'Registration', 'REF-296810', '2026-04-05', 'Accepted', '2026-04-12', NULL),
('APP-2026-00507', 3, 'Acquisition', 'ACQ-10517-26', '2026-04-01', 'Accepted', '2026-04-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000501', 'APP-2026-00507', '2026-04-07', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00367', 'APP-2026-00507', '2026-06-01', '2026-06-01', '2027-05-31', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00508', 'AP-00044', 'GF-00020', '2026-04-01', 'Renewal', 'Approved', '2026-04-08', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00124', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00508', 1, 'Identity', 'DOC-587591', '2026-04-01', 'Accepted', '2026-04-05', NULL),
('APP-2026-00508', 2, 'Registration', 'REF-188062', '2026-04-04', 'Accepted', '2026-04-05', NULL),
('APP-2026-00508', 3, 'PriorPermit', 'PM-2025-00124', '2026-04-05', 'Accepted', '2026-04-06', NULL),
('APP-2026-00508', 4, 'Other', 'FILE-911932', '2026-04-05', 'Accepted', '2026-04-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000502', 'APP-2026-00508', '2026-04-08', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00368', 'APP-2026-00508', '2026-04-10', '2026-04-10', '2027-04-09', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00509', 'AP-00165', 'GF-00042', '2026-04-02', 'New', 'Approved', '2026-04-06', 'LC07', 'Pulo Verde', 'ACQ-19064-26', '2026-02-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00509', 1, 'Identity', 'FILE-480341', '2026-04-02', 'Accepted', '2026-04-03', NULL),
('APP-2026-00509', 2, 'Registration', 'DOC-500130', '2026-04-02', 'Accepted', '2026-04-06', NULL),
('APP-2026-00509', 3, 'Acquisition', 'ACQ-19064-26', '2026-04-06', 'Accepted', '2026-04-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000503', 'APP-2026-00509', '2026-04-06', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00369', 'APP-2026-00509', '2026-04-09', '2026-04-09', '2027-04-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00510', 'AP-00076', 'GF-00127', '2026-04-04', 'New', 'Approved', '2026-05-15', 'LC06', 'Maligaya', 'ACQ-66251-26', '2026-01-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00510', 1, 'Identity', 'REF-707549', '2026-04-04', 'Accepted', '2026-04-11', NULL),
('APP-2026-00510', 2, 'Registration', 'FILE-898503', '2026-04-04', 'Accepted', '2026-04-10', NULL),
('APP-2026-00510', 3, 'Acquisition', 'ACQ-66251-26', '2026-04-06', 'Accepted', '2026-04-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000504', 'APP-2026-00510', '2026-04-05', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00370', 'APP-2026-00510', '2026-05-16', '2026-05-16', '2027-05-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00511', 'AP-00125', 'GF-00029', '2026-04-04', 'New', 'Approved', '2026-04-27', 'LC04', 'Bagong Silangan', 'ACQ-44632-26', '2026-02-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00511', 1, 'Identity', 'DOC-561637', '2026-04-04', 'Accepted', '2026-04-11', NULL),
('APP-2026-00511', 2, 'Registration', 'REF-883579', '2026-04-06', 'Accepted', '2026-04-11', NULL),
('APP-2026-00511', 3, 'Acquisition', 'ACQ-44632-26', '2026-04-08', 'Accepted', '2026-04-15', NULL),
('APP-2026-00511', 4, 'Other', 'DOC-998174', '2026-04-04', 'Accepted', '2026-04-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000505', 'APP-2026-00511', '2026-04-04', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00371', 'APP-2026-00511', '2026-05-01', '2026-05-01', '2027-04-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00512', 'AP-00176', 'GF-00064', '2026-04-04', 'New', 'Approved', '2026-05-09', 'LC04', 'Bagong Silangan', 'ACQ-59496-26', '2026-02-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00512', 1, 'Identity', 'DOC-647693', '2026-04-04', 'Accepted', '2026-04-09', NULL),
('APP-2026-00512', 2, 'Registration', 'REF-672123', '2026-04-06', 'Accepted', '2026-04-08', NULL),
('APP-2026-00512', 3, 'Acquisition', 'ACQ-59496-26', '2026-04-07', 'Accepted', '2026-04-10', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00513', 'AP-00129', 'GF-00069', '2026-04-04', 'Replacement', 'Approved', '2026-04-27', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2026-03-14', 'IR-2026-2503');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00513', 1, 'Identity', 'DOC-15561', '2026-04-04', 'Accepted', '2026-04-07', NULL),
('APP-2026-00513', 2, 'Registration', 'DOC-418553', '2026-04-05', 'Accepted', '2026-04-06', NULL),
('APP-2026-00513', 3, 'Incident', 'IR-2026-2503', '2026-04-05', 'Accepted', '2026-04-10', NULL),
('APP-2026-00513', 4, 'Other', 'DOC-185108', '2026-04-09', 'Accepted', '2026-04-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000506', 'APP-2026-00513', '2026-04-04', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00514', 'AP-00062', 'GF-00128', '2026-04-05', 'Renewal', 'Approved', '2026-04-18', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00043', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00514', 1, 'Identity', 'FILE-999067', '2026-04-05', 'Accepted', '2026-04-12', NULL),
('APP-2026-00514', 2, 'Registration', 'FILE-442289', '2026-04-10', 'Accepted', '2026-04-11', NULL),
('APP-2026-00514', 3, 'PriorPermit', 'PM-2025-00043', '2026-04-05', 'Accepted', '2026-04-09', NULL),
('APP-2026-00514', 4, 'Other', 'REF-282084', '2026-04-09', 'Accepted', '2026-04-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000507', 'APP-2026-00514', '2026-04-05', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00372', 'APP-2026-00514', '2026-04-19', '2026-04-19', '2027-04-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00515', 'AP-00058', 'GF-00105', '2026-04-06', 'New', 'Approved', '2026-04-09', 'LC03', 'Mabini East', 'ACQ-23876-26', '2025-12-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00515', 1, 'Identity', 'REF-207417', '2026-04-06', 'Accepted', '2026-04-09', NULL),
('APP-2026-00515', 2, 'Registration', 'FILE-454172', '2026-04-09', 'Accepted', '2026-04-09', NULL),
('APP-2026-00515', 3, 'Acquisition', 'ACQ-23876-26', '2026-04-09', 'Accepted', '2026-04-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000508', 'APP-2026-00515', '2026-04-09', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00373', 'APP-2026-00515', '2026-04-11', '2026-04-11', '2027-04-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00516', 'AP-00067', 'GF-00080', '2026-04-06', 'New', 'Approved', '2026-04-15', 'LC04', 'Bagong Silangan', 'ACQ-94004-26', '2025-12-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00516', 1, 'Identity', 'DOC-66408', '2026-04-06', 'Accepted', '2026-04-13', NULL),
('APP-2026-00516', 2, 'Registration', 'DOC-114650', '2026-04-09', 'Accepted', '2026-04-13', NULL),
('APP-2026-00516', 3, 'Acquisition', 'ACQ-94004-26', '2026-04-11', 'Accepted', '2026-04-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000509', 'APP-2026-00516', '2026-04-15', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00374', 'APP-2026-00516', '2026-04-19', '2026-04-19', '2027-04-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00517', 'AP-00180', 'GF-00145', '2026-04-06', 'Renewal', 'UnderReview', NULL, 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00158', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00517', 1, 'Identity', 'DOC-456371', '2026-04-06', 'Pending', NULL, NULL),
('APP-2026-00517', 2, 'Registration', 'REF-197864', '2026-04-11', 'NeedsCorrection', '2026-04-14', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00517', 3, 'PriorPermit', 'PM-2025-00158', '2026-04-06', 'NeedsCorrection', '2026-04-11', 'The recorded reference must be verified with the submitted copy.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00518', 'AP-00070', 'GF-00015', '2026-04-08', 'New', 'Approved', '2026-04-16', 'LC01', 'Luntian Central', 'ACQ-83147-26', '2026-02-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00518', 1, 'Identity', 'REF-472283', '2026-04-08', 'Accepted', '2026-04-11', NULL),
('APP-2026-00518', 2, 'Registration', 'REF-939132', '2026-04-10', 'Accepted', '2026-04-16', NULL),
('APP-2026-00518', 3, 'Acquisition', 'ACQ-83147-26', '2026-04-11', 'Accepted', '2026-04-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000510', 'APP-2026-00518', '2026-04-16', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00375', 'APP-2026-00518', '2026-04-16', '2026-04-16', '2027-04-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00519', 'AP-00148', 'GF-00151', '2026-04-08', 'New', 'Approved', '2026-04-19', 'LC06', 'Maligaya', 'ACQ-99580-26', '2026-02-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00519', 1, 'Identity', 'DOC-280398', '2026-04-08', 'Accepted', '2026-04-15', NULL),
('APP-2026-00519', 2, 'Registration', 'DOC-606481', '2026-04-09', 'Accepted', '2026-04-10', NULL),
('APP-2026-00519', 3, 'Acquisition', 'ACQ-99580-26', '2026-04-10', 'Accepted', '2026-04-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000511', 'APP-2026-00519', '2026-04-12', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00376', 'APP-2026-00519', '2026-04-22', '2026-04-22', '2027-04-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00520', 'AP-00089', 'GF-00122', '2026-04-10', 'Replacement', 'Approved', '2026-04-14', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2026-04-06', 'IR-2026-3564');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00520', 1, 'Identity', 'FILE-845165', '2026-04-10', 'Accepted', '2026-04-14', NULL),
('APP-2026-00520', 2, 'Registration', 'DOC-405738', '2026-04-14', 'Accepted', '2026-04-14', NULL),
('APP-2026-00520', 3, 'Incident', 'IR-2026-3564', '2026-04-13', 'Accepted', '2026-04-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000512', 'APP-2026-00520', '2026-04-11', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00377', 'APP-2026-00520', '2026-04-16', '2026-04-16', '2027-04-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00521', 'AP-00011', 'GF-00052', '2026-04-11', 'New', 'Approved', '2026-04-28', 'LC03', 'Mabini East', 'ACQ-95423-26', '2026-03-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00521', 1, 'Identity', 'REF-352346', '2026-04-11', 'Accepted', '2026-04-16', NULL),
('APP-2026-00521', 2, 'Registration', 'REF-53274', '2026-04-11', 'Accepted', '2026-04-14', NULL),
('APP-2026-00521', 3, 'Acquisition', 'ACQ-95423-26', '2026-04-15', 'Accepted', '2026-04-19', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000513', 'APP-2026-00521', '2026-04-19', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00378', 'APP-2026-00521', '2026-05-01', '2026-05-01', '2027-04-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00522', 'AP-00034', 'GF-00012', '2026-04-12', 'New', 'Approved', '2026-04-20', 'LC04', 'Bagong Silangan', 'ACQ-93505-26', '2026-03-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00522', 1, 'Identity', 'DOC-798631', '2026-04-12', 'Accepted', '2026-04-13', NULL),
('APP-2026-00522', 2, 'Registration', 'FILE-202425', '2026-04-15', 'Accepted', '2026-04-19', NULL),
('APP-2026-00522', 3, 'Acquisition', 'ACQ-93505-26', '2026-04-14', 'Accepted', '2026-04-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000514', 'APP-2026-00522', '2026-04-20', 600, 'Online'),
('OR-2026-000515', 'APP-2026-00522', '2026-04-13', 150, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00379', 'APP-2026-00522', '2026-04-22', '2026-04-22', '2027-04-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00523', 'AP-00018', 'GF-00033', '2026-04-17', 'Renewal', 'Approved', '2026-04-20', 'LC05', 'Santa Elena', NULL, NULL, 'PM-2025-00208', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00523', 1, 'Identity', 'DOC-700602', '2026-04-17', 'Accepted', '2026-04-20', NULL),
('APP-2026-00523', 2, 'Registration', 'DOC-462340', '2026-04-20', 'Accepted', '2026-04-20', NULL),
('APP-2026-00523', 3, 'PriorPermit', 'PM-2025-00208', '2026-04-20', 'Accepted', '2026-04-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000516', 'APP-2026-00523', '2026-04-20', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00380', 'APP-2026-00523', '2026-04-25', '2026-04-25', '2027-04-24', 'Revoked');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00524', 'AP-00011', 'GF-00018', '2026-04-20', 'New', 'Withdrawn', NULL, 'LC03', 'Mabini East', 'ACQ-65893-26', '2026-04-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00524', 1, 'Identity', 'DOC-386536', '2026-04-20', 'Accepted', '2026-04-23', NULL),
('APP-2026-00524', 2, 'Registration', 'REF-348065', '2026-04-21', 'Accepted', '2026-04-23', NULL),
('APP-2026-00524', 3, 'Acquisition', 'ACQ-65893-26', '2026-04-22', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00525', 'AP-00032', 'GF-00149', '2026-04-21', 'New', 'Rejected', '2026-04-29', 'LC08', 'San Rafael Norte', 'ACQ-55985-26', '2026-01-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00525', 1, 'Identity', 'DOC-519341', '2026-04-21', 'NeedsCorrection', '2026-04-22', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00525', 2, 'Registration', 'REF-246749', '2026-04-23', 'Accepted', '2026-04-25', NULL),
('APP-2026-00525', 3, 'Acquisition', 'ACQ-55985-26', '2026-04-26', 'Accepted', '2026-04-29', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00526', 'AP-00097', 'GF-00036', '2026-04-22', 'Replacement', 'Approved', '2026-05-04', 'LC05', 'Santa Elena', NULL, NULL, NULL, NULL, '2026-03-31', 'IR-2026-1838');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00526', 1, 'Identity', 'DOC-240289', '2026-04-22', 'Accepted', '2026-04-25', NULL),
('APP-2026-00526', 2, 'Registration', 'DOC-289479', '2026-04-24', 'Accepted', '2026-04-26', NULL),
('APP-2026-00526', 3, 'Incident', 'IR-2026-1838', '2026-04-22', 'Accepted', '2026-04-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000517', 'APP-2026-00526', '2026-04-22', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00381', 'APP-2026-00526', '2026-05-05', '2026-05-05', '2027-05-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00527', 'AP-00111', 'GF-00038', '2026-04-23', 'New', 'Approved', '2026-04-28', 'LC05', 'Santa Elena', 'ACQ-78353-26', '2026-01-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00527', 1, 'Identity', 'REF-969108', '2026-04-23', 'Accepted', '2026-04-24', NULL),
('APP-2026-00527', 2, 'Registration', 'REF-438871', '2026-04-23', 'Accepted', '2026-04-26', NULL),
('APP-2026-00527', 3, 'Acquisition', 'ACQ-78353-26', '2026-04-24', 'Accepted', '2026-04-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000518', 'APP-2026-00527', '2026-04-27', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00382', 'APP-2026-00527', '2026-05-01', '2026-05-01', '2027-04-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00528', 'AP-00125', 'GF-00109', '2026-04-23', 'Renewal', 'Approved', '2026-05-04', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00057', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00528', 1, 'Identity', 'DOC-986879', '2026-04-23', 'Accepted', '2026-04-24', NULL),
('APP-2026-00528', 2, 'Registration', 'FILE-732575', '2026-04-25', 'Accepted', '2026-05-02', NULL),
('APP-2026-00528', 3, 'PriorPermit', 'PM-2025-00057', '2026-04-28', 'Accepted', '2026-05-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000519', 'APP-2026-00528', '2026-04-23', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00383', 'APP-2026-00528', '2026-05-09', '2026-05-09', '2027-05-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00529', 'AP-00091', 'GF-00019', '2026-04-24', 'New', 'Approved', '2026-05-02', 'LC02', 'San Isidro Heights', 'ACQ-76777-26', '2026-03-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00529', 1, 'Identity', 'DOC-773889', '2026-04-24', 'Accepted', '2026-04-28', NULL),
('APP-2026-00529', 2, 'Registration', 'DOC-618501', '2026-04-28', 'Accepted', '2026-05-02', NULL),
('APP-2026-00529', 3, 'Acquisition', 'ACQ-76777-26', '2026-04-25', 'Accepted', '2026-05-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000520', 'APP-2026-00529', '2026-05-02', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00384', 'APP-2026-00529', '2026-05-07', '2026-05-07', '2027-05-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00530', 'AP-00123', 'GF-00048', '2026-04-25', 'Renewal', 'Approved', '2026-05-05', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00078', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00530', 1, 'Identity', 'FILE-281084', '2026-04-25', 'Accepted', '2026-05-01', NULL),
('APP-2026-00530', 2, 'Registration', 'REF-981091', '2026-04-28', 'Accepted', '2026-05-02', NULL),
('APP-2026-00530', 3, 'PriorPermit', 'PM-2025-00078', '2026-04-25', 'Accepted', '2026-04-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000521', 'APP-2026-00530', '2026-04-25', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00385', 'APP-2026-00530', '2026-05-06', '2026-05-06', '2027-05-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00531', 'AP-00021', 'GF-00118', '2026-04-25', 'Renewal', 'Rejected', '2026-05-06', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00181', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00531', 1, 'Identity', 'DOC-123833', '2026-04-25', 'Accepted', '2026-04-26', NULL),
('APP-2026-00531', 2, 'Registration', 'DOC-863543', '2026-04-29', 'Accepted', '2026-05-02', NULL),
('APP-2026-00531', 3, 'PriorPermit', 'PM-2025-00181', '2026-04-25', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000522', 'APP-2026-00531', '2026-05-06', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00532', 'AP-00145', 'GF-00101', '2026-04-26', 'New', 'Approved', '2026-05-03', 'LC04', 'Bagong Silangan', 'ACQ-46363-26', '2026-03-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00532', 1, 'Identity', 'DOC-971967', '2026-04-26', 'Accepted', '2026-04-28', NULL),
('APP-2026-00532', 2, 'Registration', 'FILE-689833', '2026-04-26', 'Accepted', '2026-05-01', NULL),
('APP-2026-00532', 3, 'Acquisition', 'ACQ-46363-26', '2026-04-26', 'Accepted', '2026-04-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000523', 'APP-2026-00532', '2026-05-03', 900, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00533', 'AP-00166', 'GF-00163', '2026-04-26', 'New', 'Approved', '2026-04-30', 'LC05', 'Santa Elena', 'ACQ-85379-26', '2026-03-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00533', 1, 'Identity', 'DOC-896788', '2026-04-26', 'Accepted', '2026-04-27', NULL),
('APP-2026-00533', 2, 'Registration', 'FILE-907694', '2026-04-28', 'Accepted', '2026-04-30', NULL),
('APP-2026-00533', 3, 'Acquisition', 'ACQ-85379-26', '2026-04-27', 'Accepted', '2026-04-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000524', 'APP-2026-00533', '2026-04-26', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00386', 'APP-2026-00533', '2026-05-03', '2026-05-03', '2027-05-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00534', 'AP-00081', 'GF-00070', '2026-04-27', 'New', 'Approved', '2026-06-06', 'LC03', 'Mabini East', 'ACQ-18895-26', '2026-01-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00534', 1, 'Identity', 'REF-482499', '2026-04-27', 'Accepted', '2026-04-29', NULL),
('APP-2026-00534', 2, 'Registration', 'FILE-844614', '2026-04-28', 'Accepted', '2026-05-04', NULL),
('APP-2026-00534', 3, 'Acquisition', 'ACQ-18895-26', '2026-04-28', 'Accepted', '2026-05-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000525', 'APP-2026-00534', '2026-05-02', 750, 'Cash'),
('OR-2026-000526', 'APP-2026-00534', '2026-05-01', 200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00387', 'APP-2026-00534', '2026-06-09', '2026-06-09', '2027-06-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00535', 'AP-00154', 'GF-00117', '2026-05-01', 'New', 'Approved', '2026-05-16', 'LC01', 'Luntian Central', 'ACQ-30504-26', '2026-03-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00535', 1, 'Identity', 'FILE-147977', '2026-05-01', 'Accepted', '2026-05-07', NULL),
('APP-2026-00535', 2, 'Registration', 'FILE-617619', '2026-05-01', 'Accepted', '2026-05-06', NULL),
('APP-2026-00535', 3, 'Acquisition', 'ACQ-30504-26', '2026-05-02', 'Accepted', '2026-05-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000527', 'APP-2026-00535', '2026-05-07', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00388', 'APP-2026-00535', '2026-05-19', '2026-05-19', '2027-05-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00536', 'AP-00170', 'GF-00030', '2026-05-04', 'Renewal', 'Submitted', NULL, 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00159', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00536', 1, 'Identity', 'REF-125304', '2026-05-04', 'Pending', NULL, NULL),
('APP-2026-00536', 2, 'Registration', 'DOC-458223', '2026-05-04', 'Pending', NULL, NULL),
('APP-2026-00536', 3, 'Other', 'DOC-137705', '2026-05-06', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000528', 'APP-2026-00536', '2026-05-13', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00537', 'AP-00167', 'GF-00011', '2026-05-05', 'New', 'Approved', '2026-05-12', 'LC01', 'Luntian Central', 'ACQ-11118-26', '2026-02-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00537', 1, 'Identity', 'DOC-672375', '2026-05-05', 'Accepted', '2026-05-12', NULL),
('APP-2026-00537', 2, 'Registration', 'FILE-620001', '2026-05-06', 'Accepted', '2026-05-12', NULL),
('APP-2026-00537', 3, 'Acquisition', 'ACQ-11118-26', '2026-05-06', 'Accepted', '2026-05-12', NULL),
('APP-2026-00537', 4, 'Other', 'FILE-478706', '2026-05-05', 'Accepted', '2026-05-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000529', 'APP-2026-00537', '2026-05-11', 1200, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00538', 'AP-00070', 'GF-00035', '2026-05-06', 'New', 'Approved', '2026-05-31', 'LC01', 'Luntian Central', 'ACQ-84571-26', '2026-03-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00538', 1, 'Identity', 'REF-293737', '2026-05-06', 'Accepted', '2026-05-13', NULL),
('APP-2026-00538', 2, 'Registration', 'FILE-587125', '2026-05-11', 'Accepted', '2026-05-17', NULL),
('APP-2026-00538', 3, 'Acquisition', 'ACQ-84571-26', '2026-05-09', 'Accepted', '2026-05-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000530', 'APP-2026-00538', '2026-05-06', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00389', 'APP-2026-00538', '2026-06-02', '2026-06-02', '2027-06-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00539', 'AP-00121', 'GF-00061', '2026-05-06', 'Renewal', 'Approved', '2026-05-29', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2024-00001', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00539', 1, 'Identity', 'DOC-876190', '2026-05-06', 'Accepted', '2026-05-13', NULL),
('APP-2026-00539', 2, 'Registration', 'REF-468712', '2026-05-08', 'Accepted', '2026-05-12', NULL),
('APP-2026-00539', 3, 'PriorPermit', 'PM-2024-00001', '2026-05-10', 'Accepted', '2026-05-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000531', 'APP-2026-00539', '2026-05-15', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00390', 'APP-2026-00539', '2026-06-03', '2026-06-03', '2027-06-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00540', 'AP-00139', 'GF-00132', '2026-05-06', 'Renewal', 'Rejected', '2026-05-26', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00170', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00540', 1, 'Identity', 'FILE-768541', '2026-05-06', 'Pending', NULL, NULL),
('APP-2026-00540', 2, 'Registration', 'DOC-174685', '2026-05-09', 'NeedsCorrection', '2026-05-13', 'The submitted name requires clarification against the application.'),
('APP-2026-00540', 3, 'PriorPermit', 'PM-2025-00170', '2026-05-08', 'NeedsCorrection', '2026-05-13', 'The date on the document needs clarification.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000532', 'APP-2026-00540', '2026-05-06', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00541', 'AP-00025', 'GF-00049', '2026-05-07', 'New', 'Approved', '2026-05-17', 'LC03', 'Mabini East', 'ACQ-59605-26', '2026-03-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00541', 1, 'Identity', 'REF-768130', '2026-05-07', 'Accepted', '2026-05-14', NULL),
('APP-2026-00541', 2, 'Registration', 'FILE-116363', '2026-05-08', 'Accepted', '2026-05-14', NULL),
('APP-2026-00541', 3, 'Acquisition', 'ACQ-59605-26', '2026-05-11', 'Accepted', '2026-05-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000533', 'APP-2026-00541', '2026-05-16', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00391', 'APP-2026-00541', '2026-05-22', '2026-05-22', '2027-05-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00542', 'AP-00144', 'GF-00159', '2026-05-07', 'New', 'Approved', '2026-05-10', 'LC02', 'San Isidro Heights', 'ACQ-26120-26', '2026-02-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00542', 1, 'Identity', 'FILE-783873', '2026-05-07', 'Accepted', '2026-05-08', NULL),
('APP-2026-00542', 2, 'Registration', 'REF-326784', '2026-05-10', 'Accepted', '2026-05-10', NULL),
('APP-2026-00542', 3, 'Acquisition', 'ACQ-26120-26', '2026-05-10', 'Accepted', '2026-05-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000534', 'APP-2026-00542', '2026-05-10', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00392', 'APP-2026-00542', '2026-05-14', '2026-05-14', '2027-05-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00543', 'AP-00051', 'GF-00006', '2026-05-09', 'New', 'Rejected', '2026-05-30', 'LC02', 'San Isidro Heights', 'ACQ-43443-26', '2026-01-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00543', 1, 'Identity', 'FILE-757799', '2026-05-09', 'Accepted', '2026-05-10', NULL),
('APP-2026-00543', 2, 'Registration', 'FILE-681488', '2026-05-12', 'Pending', NULL, NULL),
('APP-2026-00543', 3, 'Acquisition', 'ACQ-43443-26', '2026-05-13', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000535', 'APP-2026-00543', '2026-05-11', 1200, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00544', 'AP-00187', 'GF-00131', '2026-05-11', 'New', 'Approved', '2026-06-04', 'LC06', 'Maligaya', 'ACQ-37983-26', '2026-02-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00544', 1, 'Identity', 'FILE-774572', '2026-05-11', 'Accepted', '2026-05-16', NULL),
('APP-2026-00544', 2, 'Registration', 'FILE-381441', '2026-05-13', 'Accepted', '2026-05-19', NULL),
('APP-2026-00544', 3, 'Acquisition', 'ACQ-37983-26', '2026-05-14', 'Accepted', '2026-05-17', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000536', 'APP-2026-00544', '2026-05-18', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00393', 'APP-2026-00544', '2026-06-08', '2026-06-08', '2027-06-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00545', 'AP-00084', 'GF-00077', '2026-05-11', 'Renewal', 'Approved', '2026-06-02', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00156', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00545', 1, 'Identity', 'DOC-324460', '2026-05-11', 'Accepted', '2026-05-14', NULL),
('APP-2026-00545', 2, 'Registration', 'DOC-227328', '2026-05-12', 'Accepted', '2026-05-16', NULL),
('APP-2026-00545', 3, 'PriorPermit', 'PM-2025-00156', '2026-05-11', 'Accepted', '2026-05-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000537', 'APP-2026-00545', '2026-05-12', 900, 'Online'),
('OR-2026-000538', 'APP-2026-00545', '2026-05-19', 100, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00394', 'APP-2026-00545', '2026-06-07', '2026-06-07', '2027-06-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00546', 'AP-00130', 'GF-00084', '2026-05-13', 'New', 'Approved', '2026-05-22', 'LC01', 'Luntian Central', 'ACQ-58524-26', '2026-05-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00546', 1, 'Identity', 'FILE-460314', '2026-05-13', 'Accepted', '2026-05-20', NULL),
('APP-2026-00546', 2, 'Registration', 'FILE-699701', '2026-05-18', 'Accepted', '2026-05-22', NULL),
('APP-2026-00546', 3, 'Acquisition', 'ACQ-58524-26', '2026-05-14', 'Accepted', '2026-05-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000539', 'APP-2026-00546', '2026-05-21', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00395', 'APP-2026-00546', '2026-05-24', '2026-05-24', '2027-05-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00547', 'AP-00051', 'GF-00046', '2026-05-14', 'New', 'Approved', '2026-06-08', 'LC02', 'San Isidro Heights', 'ACQ-34345-26', '2026-02-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00547', 1, 'Identity', 'DOC-496046', '2026-05-14', 'Accepted', '2026-05-15', NULL),
('APP-2026-00547', 2, 'Registration', 'REF-868084', '2026-05-15', 'Accepted', '2026-05-20', NULL),
('APP-2026-00547', 3, 'Acquisition', 'ACQ-34345-26', '2026-05-14', 'Accepted', '2026-05-15', NULL),
('APP-2026-00547', 4, 'Other', 'REF-556802', '2026-05-19', 'Accepted', '2026-05-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000540', 'APP-2026-00547', '2026-05-15', 1200, 'Cash'),
('OR-2026-000541', 'APP-2026-00547', '2026-05-21', 150, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00548', 'AP-00138', 'GF-00048', '2026-05-15', 'New', 'UnderReview', NULL, 'LC01', 'Luntian Central', 'ACQ-83729-26', '2026-03-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00548', 1, 'Identity', 'DOC-294845', '2026-05-15', 'Pending', NULL, NULL),
('APP-2026-00548', 2, 'Registration', 'FILE-742616', '2026-05-16', 'Accepted', '2026-05-17', NULL),
('APP-2026-00548', 3, 'Acquisition', 'ACQ-83729-26', '2026-05-16', 'Accepted', '2026-05-23', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00549', 'AP-00102', 'GF-00146', '2026-05-17', 'Renewal', 'Approved', '2026-06-05', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00075', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00549', 1, 'Identity', 'FILE-64538', '2026-05-17', 'Accepted', '2026-05-22', NULL),
('APP-2026-00549', 2, 'Registration', 'DOC-946887', '2026-05-19', 'Accepted', '2026-05-22', NULL),
('APP-2026-00549', 3, 'PriorPermit', 'PM-2025-00075', '2026-05-18', 'Accepted', '2026-05-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000542', 'APP-2026-00549', '2026-05-19', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00396', 'APP-2026-00549', '2026-06-08', '2026-06-08', '2027-06-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00550', 'AP-00015', 'GF-00130', '2026-05-18', 'Renewal', 'Approved', '2026-06-22', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00093', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00550', 1, 'Identity', 'REF-140552', '2026-05-18', 'Accepted', '2026-05-22', NULL),
('APP-2026-00550', 2, 'Registration', 'REF-577590', '2026-05-23', 'Accepted', '2026-05-30', NULL),
('APP-2026-00550', 3, 'PriorPermit', 'PM-2025-00093', '2026-05-21', 'Accepted', '2026-05-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000543', 'APP-2026-00550', '2026-05-25', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00397', 'APP-2026-00550', '2026-06-22', '2026-06-22', '2027-06-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00551', 'AP-00166', 'GF-00006', '2026-05-19', 'New', 'Approved', '2026-06-05', 'LC05', 'Santa Elena', 'ACQ-97409-26', '2026-02-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00551', 1, 'Identity', 'FILE-933119', '2026-05-19', 'Accepted', '2026-05-24', NULL),
('APP-2026-00551', 2, 'Registration', 'DOC-10652', '2026-05-24', 'Accepted', '2026-05-28', NULL),
('APP-2026-00551', 3, 'Acquisition', 'ACQ-97409-26', '2026-05-24', 'Accepted', '2026-05-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000544', 'APP-2026-00551', '2026-05-30', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00398', 'APP-2026-00551', '2026-06-09', '2026-06-09', '2027-06-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00552', 'AP-00137', 'GF-00056', '2026-05-19', 'New', 'Approved', '2026-06-07', 'LC03', 'Mabini East', 'ACQ-90623-26', '2026-04-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00552', 1, 'Identity', 'FILE-878348', '2026-05-19', 'Accepted', '2026-05-22', NULL),
('APP-2026-00552', 2, 'Registration', 'DOC-53720', '2026-05-24', 'Accepted', '2026-05-28', NULL),
('APP-2026-00552', 3, 'Acquisition', 'ACQ-90623-26', '2026-05-19', 'Accepted', '2026-05-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000545', 'APP-2026-00552', '2026-05-21', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00399', 'APP-2026-00552', '2026-06-12', '2026-06-12', '2027-06-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00553', 'AP-00052', 'GF-00030', '2026-05-19', 'New', 'Approved', '2026-06-18', 'LC01', 'Luntian Central', 'ACQ-69316-26', '2026-01-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00553', 1, 'Identity', 'DOC-995056', '2026-05-19', 'Accepted', '2026-05-23', NULL),
('APP-2026-00553', 2, 'Registration', 'FILE-120685', '2026-05-22', 'Accepted', '2026-05-23', NULL),
('APP-2026-00553', 3, 'Acquisition', 'ACQ-69316-26', '2026-05-21', 'Accepted', '2026-05-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000546', 'APP-2026-00553', '2026-05-24', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00554', 'AP-00120', 'GF-00124', '2026-05-21', 'New', 'Approved', '2026-06-13', 'LC02', 'San Isidro Heights', 'ACQ-34291-26', '2026-03-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00554', 1, 'Identity', 'REF-776517', '2026-05-21', 'Accepted', '2026-05-25', NULL),
('APP-2026-00554', 2, 'Registration', 'FILE-901916', '2026-05-25', 'Accepted', '2026-05-31', NULL),
('APP-2026-00554', 3, 'Acquisition', 'ACQ-34291-26', '2026-05-26', 'Accepted', '2026-06-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000547', 'APP-2026-00554', '2026-05-30', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00400', 'APP-2026-00554', '2026-06-18', '2026-06-18', '2027-06-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00555', 'AP-00176', 'GF-00007', '2026-05-23', 'New', 'Approved', '2026-06-24', 'LC04', 'Bagong Silangan', 'ACQ-64357-26', '2026-03-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00555', 1, 'Identity', 'DOC-924833', '2026-05-23', 'Accepted', '2026-05-29', NULL),
('APP-2026-00555', 2, 'Registration', 'REF-271605', '2026-05-25', 'Accepted', '2026-05-29', NULL),
('APP-2026-00555', 3, 'Acquisition', 'ACQ-64357-26', '2026-05-26', 'Accepted', '2026-05-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000548', 'APP-2026-00555', '2026-06-01', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00401', 'APP-2026-00555', '2026-06-26', '2026-06-26', '2027-06-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00556', 'AP-00039', 'GF-00080', '2026-05-24', 'New', 'Approved', '2026-05-27', 'LC01', 'Luntian Central', 'ACQ-94517-26', '2026-03-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00556', 1, 'Identity', 'REF-413414', '2026-05-24', 'Accepted', '2026-05-27', NULL),
('APP-2026-00556', 2, 'Registration', 'REF-854657', '2026-05-27', 'Accepted', '2026-05-27', NULL),
('APP-2026-00556', 3, 'Acquisition', 'ACQ-94517-26', '2026-05-24', 'Accepted', '2026-05-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000549', 'APP-2026-00556', '2026-05-27', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00402', 'APP-2026-00556', '2026-05-31', '2026-05-31', '2027-05-30', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00557', 'AP-00091', 'GF-00101', '2026-05-25', 'New', 'Approved', '2026-05-31', 'LC02', 'San Isidro Heights', 'ACQ-38569-26', '2026-01-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00557', 1, 'Identity', 'DOC-531647', '2026-05-25', 'Accepted', '2026-05-29', NULL),
('APP-2026-00557', 2, 'Registration', 'FILE-369913', '2026-05-25', 'Accepted', '2026-05-31', NULL),
('APP-2026-00557', 3, 'Acquisition', 'ACQ-38569-26', '2026-05-26', 'Accepted', '2026-05-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000550', 'APP-2026-00557', '2026-05-25', 1200, 'BankTransfer'),
('OR-2026-000551', 'APP-2026-00557', '2026-05-27', 250, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00403', 'APP-2026-00557', '2026-06-02', '2026-06-02', '2027-06-01', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00558', 'AP-00145', 'GF-00109', '2026-05-28', 'New', 'Rejected', '2026-06-07', 'LC04', 'Bagong Silangan', 'ACQ-19309-26', '2026-02-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00558', 1, 'Identity', 'REF-590389', '2026-05-28', 'Accepted', '2026-05-30', NULL),
('APP-2026-00558', 2, 'Registration', 'DOC-774677', '2026-06-02', 'Accepted', '2026-06-07', NULL),
('APP-2026-00558', 3, 'Acquisition', 'ACQ-19309-26', '2026-05-29', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000552', 'APP-2026-00558', '2026-06-03', 600, 'BankTransfer'),
('OR-2026-000553', 'APP-2026-00558', '2026-06-07', 100, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00559', 'AP-00159', 'GF-00081', '2026-05-29', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-84794-26', '2026-04-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00559', 1, 'Identity', 'DOC-190862', '2026-05-29', 'Pending', NULL, NULL),
('APP-2026-00559', 2, 'Registration', 'REF-329739', '2026-05-31', 'Accepted', '2026-06-07', NULL),
('APP-2026-00559', 3, 'Acquisition', 'ACQ-84794-26', '2026-06-01', 'Accepted', '2026-06-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000554', 'APP-2026-00559', '2026-05-31', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00560', 'AP-00132', 'GF-00017', '2026-05-30', 'New', 'Approved', '2026-06-15', 'LC02', 'San Isidro Heights', 'ACQ-79561-26', '2026-04-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00560', 1, 'Identity', 'FILE-996907', '2026-05-30', 'Accepted', '2026-06-04', NULL),
('APP-2026-00560', 2, 'Registration', 'REF-556179', '2026-06-03', 'Accepted', '2026-06-06', NULL),
('APP-2026-00560', 3, 'Acquisition', 'ACQ-79561-26', '2026-05-30', 'Accepted', '2026-06-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000555', 'APP-2026-00560', '2026-06-02', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00404', 'APP-2026-00560', '2026-06-16', '2026-06-16', '2027-06-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00561', 'AP-00172', 'GF-00154', '2026-05-30', 'Replacement', 'Rejected', '2026-06-21', 'LC06', 'Maligaya', NULL, NULL, NULL, NULL, '2026-05-02', 'IR-2026-5502');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00561', 1, 'Identity', 'REF-203768', '2026-05-30', 'NeedsCorrection', '2026-06-06', 'The submitted name requires clarification against the application.'),
('APP-2026-00561', 2, 'Registration', 'DOC-337154', '2026-06-01', 'Pending', NULL, NULL),
('APP-2026-00561', 3, 'Incident', 'IR-2026-5502', '2026-06-02', 'NeedsCorrection', '2026-06-04', 'Please provide the missing page of the supporting document.'),
('APP-2026-00561', 4, 'Other', 'FILE-969824', '2026-06-01', 'Accepted', '2026-06-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000556', 'APP-2026-00561', '2026-06-02', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00562', 'AP-00107', 'GF-00077', '2026-06-02', 'New', 'Approved', '2026-06-07', 'LC06', 'Maligaya', 'ACQ-33050-26', '2026-03-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00562', 1, 'Identity', 'DOC-975806', '2026-06-02', 'Accepted', '2026-06-04', NULL),
('APP-2026-00562', 2, 'Registration', 'REF-959778', '2026-06-06', 'Accepted', '2026-06-07', NULL),
('APP-2026-00562', 3, 'Acquisition', 'ACQ-33050-26', '2026-06-03', 'Accepted', '2026-06-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000557', 'APP-2026-00562', '2026-06-02', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00563', 'AP-00039', 'GF-00158', '2026-06-03', 'New', 'Approved', '2026-06-23', 'LC01', 'Luntian Central', 'ACQ-57860-26', '2026-05-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00563', 1, 'Identity', 'REF-536496', '2026-06-03', 'Accepted', '2026-06-07', NULL),
('APP-2026-00563', 2, 'Registration', 'DOC-838800', '2026-06-03', 'Accepted', '2026-06-06', NULL),
('APP-2026-00563', 3, 'Acquisition', 'ACQ-57860-26', '2026-06-06', 'Accepted', '2026-06-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000558', 'APP-2026-00563', '2026-06-14', 1200, 'Online'),
('OR-2026-000559', 'APP-2026-00563', '2026-06-14', 100, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00405', 'APP-2026-00563', '2026-06-24', '2026-06-24', '2027-06-23', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00564', 'AP-00067', 'GF-00154', '2026-06-03', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-82179-26', '2026-05-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00564', 1, 'Identity', 'DOC-113960', '2026-06-03', 'NeedsCorrection', '2026-06-08', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00564', 2, 'Registration', 'REF-959600', '2026-06-08', 'Pending', NULL, NULL),
('APP-2026-00564', 3, 'Acquisition', 'ACQ-82179-26', '2026-06-04', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00565', 'AP-00172', 'GF-00152', '2026-06-03', 'Renewal', 'Approved', '2026-06-06', 'LC06', 'Maligaya', NULL, NULL, 'PM-2025-00132', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00565', 1, 'Identity', 'REF-287486', '2026-06-03', 'Accepted', '2026-06-05', NULL),
('APP-2026-00565', 2, 'Registration', 'DOC-16363', '2026-06-06', 'Accepted', '2026-06-06', NULL),
('APP-2026-00565', 3, 'PriorPermit', 'PM-2025-00132', '2026-06-06', 'Accepted', '2026-06-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000560', 'APP-2026-00565', '2026-06-06', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00406', 'APP-2026-00565', '2026-06-09', '2026-06-09', '2027-06-08', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00566', 'AP-00029', 'GF-00011', '2026-06-04', 'New', 'Approved', '2026-06-17', 'LC02', 'San Isidro Heights', 'ACQ-58018-26', '2026-02-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00566', 1, 'Identity', 'REF-984742', '2026-06-04', 'Accepted', '2026-06-05', NULL),
('APP-2026-00566', 2, 'Registration', 'DOC-115928', '2026-06-08', 'Accepted', '2026-06-13', NULL),
('APP-2026-00566', 3, 'Acquisition', 'ACQ-58018-26', '2026-06-06', 'Accepted', '2026-06-11', NULL),
('APP-2026-00566', 4, 'Other', 'DOC-67047', '2026-06-08', 'Accepted', '2026-06-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000561', 'APP-2026-00566', '2026-06-10', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00407', 'APP-2026-00566', '2026-06-21', '2026-06-21', '2027-06-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00567', 'AP-00186', 'GF-00087', '2026-06-06', 'Renewal', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00215', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00567', 1, 'Identity', 'REF-398715', '2026-06-06', 'NeedsCorrection', '2026-06-10', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00567', 2, 'Registration', 'REF-942865', '2026-06-10', 'NeedsCorrection', '2026-06-16', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00567', 3, 'PriorPermit', 'PM-2025-00215', '2026-06-06', 'Accepted', '2026-06-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000562', 'APP-2026-00567', '2026-06-10', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00568', 'AP-00002', 'GF-00125', '2026-06-08', 'New', 'Approved', '2026-06-21', 'LC07', 'Pulo Verde', 'ACQ-56147-26', '2026-03-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00568', 1, 'Identity', 'FILE-856535', '2026-06-08', 'Accepted', '2026-06-10', NULL),
('APP-2026-00568', 2, 'Registration', 'REF-989348', '2026-06-09', 'Accepted', '2026-06-14', NULL),
('APP-2026-00568', 3, 'Acquisition', 'ACQ-56147-26', '2026-06-09', 'Accepted', '2026-06-10', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00408', 'APP-2026-00568', '2026-06-26', '2026-06-26', '2027-06-25', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00569', 'AP-00109', 'GF-00102', '2026-06-10', 'New', 'Approved', '2026-06-21', 'LC03', 'Mabini East', 'ACQ-82628-26', '2026-02-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00569', 1, 'Identity', 'DOC-606670', '2026-06-10', 'Accepted', '2026-06-12', NULL),
('APP-2026-00569', 2, 'Registration', 'FILE-336488', '2026-06-12', 'Accepted', '2026-06-18', NULL),
('APP-2026-00569', 3, 'Acquisition', 'ACQ-82628-26', '2026-06-11', 'Accepted', '2026-06-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000563', 'APP-2026-00569', '2026-06-10', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00409', 'APP-2026-00569', '2026-06-22', '2026-06-22', '2027-06-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00570', 'AP-00021', 'GF-00118', '2026-06-10', 'Renewal', 'Approved', '2026-06-19', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00181', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00570', 1, 'Identity', 'REF-33312', '2026-06-10', 'Accepted', '2026-06-11', NULL),
('APP-2026-00570', 2, 'Registration', 'DOC-204031', '2026-06-14', 'Accepted', '2026-06-16', NULL),
('APP-2026-00570', 3, 'PriorPermit', 'PM-2025-00181', '2026-06-15', 'Accepted', '2026-06-19', NULL),
('APP-2026-00570', 4, 'Other', 'REF-28890', '2026-06-12', 'Accepted', '2026-06-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000564', 'APP-2026-00570', '2026-06-10', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00410', 'APP-2026-00570', '2026-06-19', '2026-06-19', '2027-06-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00571', 'AP-00176', 'GF-00085', '2026-06-12', 'New', 'Submitted', NULL, 'LC04', 'Bagong Silangan', 'ACQ-17815-26', '2026-05-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00571', 1, 'Identity', 'DOC-999445', '2026-06-12', 'Pending', NULL, NULL),
('APP-2026-00571', 2, 'Registration', 'FILE-495141', '2026-06-12', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00572', 'AP-00031', 'GF-00142', '2026-06-14', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-62082-26', '2026-05-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00572', 1, 'Identity', 'DOC-143201', '2026-06-14', 'Accepted', '2026-06-17', NULL),
('APP-2026-00572', 2, 'Registration', 'DOC-530772', '2026-06-15', 'NeedsCorrection', '2026-06-20', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00572', 3, 'Acquisition', 'ACQ-62082-26', '2026-06-16', 'Accepted', '2026-06-20', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00573', 'AP-00024', 'GF-00112', '2026-06-14', 'Renewal', 'Approved', '2026-06-23', 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00185', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00573', 1, 'Identity', 'FILE-51443', '2026-06-14', 'Accepted', '2026-06-15', NULL),
('APP-2026-00573', 2, 'Registration', 'REF-632915', '2026-06-19', 'Accepted', '2026-06-22', NULL),
('APP-2026-00573', 3, 'PriorPermit', 'PM-2025-00185', '2026-06-19', 'Accepted', '2026-06-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000565', 'APP-2026-00573', '2026-06-15', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00411', 'APP-2026-00573', '2026-06-28', '2026-06-28', '2027-06-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00574', 'AP-00044', 'GF-00020', '2026-06-14', 'Renewal', 'Rejected', '2026-07-04', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00124', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00574', 1, 'Identity', 'REF-384232', '2026-06-14', 'Accepted', '2026-06-15', NULL),
('APP-2026-00574', 2, 'Registration', 'REF-440037', '2026-06-18', 'Accepted', '2026-06-25', NULL),
('APP-2026-00574', 3, 'PriorPermit', 'PM-2025-00124', '2026-06-15', 'Pending', NULL, NULL),
('APP-2026-00574', 4, 'Other', 'DOC-71173', '2026-06-16', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000566', 'APP-2026-00574', '2026-06-24', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00575', 'AP-00070', 'GF-00036', '2026-06-15', 'New', 'Approved', '2026-07-03', 'LC01', 'Luntian Central', 'ACQ-29217-26', '2026-03-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00575', 1, 'Identity', 'REF-483749', '2026-06-15', 'Accepted', '2026-06-20', NULL),
('APP-2026-00575', 2, 'Registration', 'REF-27870', '2026-06-19', 'Accepted', '2026-06-20', NULL),
('APP-2026-00575', 3, 'Acquisition', 'ACQ-29217-26', '2026-06-17', 'Accepted', '2026-06-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000567', 'APP-2026-00575', '2026-06-16', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00412', 'APP-2026-00575', '2026-07-04', '2026-07-04', '2027-07-03', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00576', 'AP-00072', 'GF-00042', '2026-06-15', 'New', 'Rejected', '2026-06-21', 'LC08', 'San Rafael Norte', 'ACQ-61768-26', '2026-03-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00576', 1, 'Identity', 'DOC-840511', '2026-06-15', 'Accepted', '2026-06-17', NULL),
('APP-2026-00576', 2, 'Registration', 'DOC-244232', '2026-06-20', 'NeedsCorrection', '2026-06-21', 'Please provide the missing page of the supporting document.'),
('APP-2026-00576', 3, 'Acquisition', 'ACQ-61768-26', '2026-06-15', 'Accepted', '2026-06-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000568', 'APP-2026-00576', '2026-06-19', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00577', 'AP-00033', 'GF-00060', '2026-06-16', 'New', 'Approved', '2026-07-04', 'LC01', 'Luntian Central', 'ACQ-11930-26', '2026-03-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00577', 1, 'Identity', 'REF-686377', '2026-06-16', 'Accepted', '2026-06-22', NULL),
('APP-2026-00577', 2, 'Registration', 'REF-660107', '2026-06-20', 'Accepted', '2026-06-27', NULL),
('APP-2026-00577', 3, 'Acquisition', 'ACQ-11930-26', '2026-06-20', 'Accepted', '2026-06-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000569', 'APP-2026-00577', '2026-06-17', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00413', 'APP-2026-00577', '2026-07-09', '2026-07-09', '2027-07-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00578', 'AP-00031', 'GF-00160', '2026-06-20', 'New', 'Approved', '2026-06-29', 'LC04', 'Bagong Silangan', 'ACQ-54819-26', '2026-05-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00578', 1, 'Identity', 'DOC-466421', '2026-06-20', 'Accepted', '2026-06-21', NULL),
('APP-2026-00578', 2, 'Registration', 'DOC-174134', '2026-06-22', 'Accepted', '2026-06-29', NULL),
('APP-2026-00578', 3, 'Acquisition', 'ACQ-54819-26', '2026-06-23', 'Accepted', '2026-06-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000570', 'APP-2026-00578', '2026-06-27', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00414', 'APP-2026-00578', '2026-07-03', '2026-07-03', '2027-07-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00579', 'AP-00144', 'GF-00049', '2026-06-21', 'New', 'Rejected', '2026-07-03', 'LC02', 'San Isidro Heights', 'ACQ-92189-26', '2026-04-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00579', 1, 'Identity', 'FILE-328658', '2026-06-21', 'NeedsCorrection', '2026-06-28', 'Please provide the missing page of the supporting document.'),
('APP-2026-00579', 2, 'Registration', 'DOC-961206', '2026-06-22', 'Accepted', '2026-06-24', NULL),
('APP-2026-00579', 3, 'Acquisition', 'ACQ-92189-26', '2026-06-24', 'Accepted', '2026-06-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000571', 'APP-2026-00579', '2026-06-24', 450, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00580', 'AP-00116', 'GF-00144', '2026-06-23', 'New', 'Approved', '2026-07-26', 'LC04', 'Bagong Silangan', 'ACQ-24222-26', '2026-05-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00580', 1, 'Identity', 'FILE-316736', '2026-06-23', 'Accepted', '2026-06-27', NULL),
('APP-2026-00580', 2, 'Registration', 'REF-114229', '2026-06-25', 'Accepted', '2026-06-28', NULL),
('APP-2026-00580', 3, 'Acquisition', 'ACQ-24222-26', '2026-06-24', 'Accepted', '2026-06-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000572', 'APP-2026-00580', '2026-06-29', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00415', 'APP-2026-00580', '2026-07-29', '2026-07-29', '2027-07-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00581', 'AP-00118', 'GF-00009', '2026-06-23', 'Renewal', 'Approved', '2026-06-28', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00141', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00581', 1, 'Identity', 'DOC-385874', '2026-06-23', 'Accepted', '2026-06-27', NULL),
('APP-2026-00581', 2, 'Registration', 'REF-354186', '2026-06-25', 'Accepted', '2026-06-28', NULL),
('APP-2026-00581', 3, 'PriorPermit', 'PM-2025-00141', '2026-06-27', 'Accepted', '2026-06-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000573', 'APP-2026-00581', '2026-06-28', 600, 'Cash'),
('OR-2026-000574', 'APP-2026-00581', '2026-06-28', 250, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00416', 'APP-2026-00581', '2026-06-28', '2026-06-28', '2027-06-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00582', 'AP-00071', 'GF-00136', '2026-06-23', 'Replacement', 'UnderReview', NULL, 'LC07', 'Pulo Verde', NULL, NULL, NULL, NULL, '2026-06-19', 'IR-2026-8263');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00582', 1, 'Identity', 'DOC-905033', '2026-06-23', 'Accepted', '2026-06-27', NULL),
('APP-2026-00582', 2, 'Registration', 'FILE-214235', '2026-06-24', 'Pending', NULL, NULL),
('APP-2026-00582', 3, 'Incident', 'IR-2026-8263', '2026-06-27', 'Accepted', '2026-07-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000575', 'APP-2026-00582', '2026-07-04', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00583', 'AP-00135', 'GF-00136', '2026-06-24', 'New', 'Rejected', '2026-07-14', 'LC01', 'Luntian Central', 'ACQ-54822-26', '2026-03-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00583', 1, 'Identity', 'FILE-50232', '2026-06-24', 'Accepted', '2026-06-29', NULL),
('APP-2026-00583', 2, 'Registration', 'DOC-864649', '2026-06-27', 'Pending', NULL, NULL),
('APP-2026-00583', 3, 'Acquisition', 'ACQ-54822-26', '2026-06-24', 'NeedsCorrection', '2026-06-26', 'Please provide the missing page of the supporting document.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000576', 'APP-2026-00583', '2026-06-26', 1200, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00584', 'AP-00004', 'GF-00100', '2026-06-24', 'Renewal', 'Rejected', '2026-06-29', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00164', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00584', 1, 'Identity', 'DOC-193376', '2026-06-24', 'Pending', NULL, NULL),
('APP-2026-00584', 2, 'Registration', 'DOC-660849', '2026-06-24', 'Pending', NULL, NULL),
('APP-2026-00584', 3, 'PriorPermit', 'PM-2025-00164', '2026-06-26', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00585', 'AP-00131', 'GF-00086', '2026-06-25', 'New', 'Approved', '2026-07-04', 'LC05', 'Santa Elena', 'ACQ-61282-26', '2026-05-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00585', 1, 'Identity', 'REF-342637', '2026-06-25', 'Accepted', '2026-06-28', NULL),
('APP-2026-00585', 2, 'Registration', 'FILE-499519', '2026-06-26', 'Accepted', '2026-07-01', NULL),
('APP-2026-00585', 3, 'Acquisition', 'ACQ-61282-26', '2026-06-25', 'Accepted', '2026-06-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000577', 'APP-2026-00585', '2026-07-01', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00417', 'APP-2026-00585', '2026-07-08', '2026-07-08', '2027-07-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00586', 'AP-00071', 'GF-00011', '2026-06-26', 'New', 'Approved', '2026-07-18', 'LC07', 'Pulo Verde', 'ACQ-91478-26', '2026-03-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00586', 1, 'Identity', 'DOC-275551', '2026-06-26', 'Accepted', '2026-07-03', NULL),
('APP-2026-00586', 2, 'Registration', 'FILE-377062', '2026-06-28', 'Accepted', '2026-07-03', NULL),
('APP-2026-00586', 3, 'Acquisition', 'ACQ-91478-26', '2026-06-28', 'Accepted', '2026-06-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000578', 'APP-2026-00586', '2026-07-08', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00418', 'APP-2026-00586', '2026-07-23', '2026-07-23', '2027-07-22', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00587', 'AP-00055', 'GF-00136', '2026-06-26', 'New', 'Approved', '2026-07-10', 'LC07', 'Pulo Verde', 'ACQ-24914-26', '2026-06-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00587', 1, 'Identity', 'FILE-583934', '2026-06-26', 'Accepted', '2026-06-29', NULL),
('APP-2026-00587', 2, 'Registration', 'DOC-92946', '2026-06-27', 'Accepted', '2026-06-29', NULL),
('APP-2026-00587', 3, 'Acquisition', 'ACQ-24914-26', '2026-06-27', 'Accepted', '2026-07-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000579', 'APP-2026-00587', '2026-06-29', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00419', 'APP-2026-00587', '2026-07-10', '2026-07-10', '2027-07-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00588', 'AP-00042', 'GF-00159', '2026-06-28', 'New', 'Approved', '2026-07-21', 'LC03', 'Mabini East', 'ACQ-38651-26', '2026-04-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00588', 1, 'Identity', 'FILE-520185', '2026-06-28', 'Accepted', '2026-07-03', NULL),
('APP-2026-00588', 2, 'Registration', 'DOC-868455', '2026-07-02', 'Accepted', '2026-07-05', NULL),
('APP-2026-00588', 3, 'Acquisition', 'ACQ-38651-26', '2026-06-29', 'Accepted', '2026-07-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000580', 'APP-2026-00588', '2026-07-06', 1200, 'Cash'),
('OR-2026-000581', 'APP-2026-00588', '2026-06-28', 150, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00420', 'APP-2026-00588', '2026-07-25', '2026-07-25', '2027-07-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00589', 'AP-00067', 'GF-00115', '2026-06-28', 'New', 'Approved', '2026-07-01', 'LC04', 'Bagong Silangan', 'ACQ-82444-26', '2026-03-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00589', 1, 'Identity', 'DOC-405965', '2026-06-28', 'Accepted', '2026-07-01', NULL),
('APP-2026-00589', 2, 'Registration', 'DOC-338242', '2026-07-01', 'Accepted', '2026-07-01', NULL),
('APP-2026-00589', 3, 'Acquisition', 'ACQ-82444-26', '2026-06-30', 'Accepted', '2026-07-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000582', 'APP-2026-00589', '2026-07-01', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00421', 'APP-2026-00589', '2026-07-05', '2026-07-05', '2027-07-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00590', 'AP-00152', 'GF-00009', '2026-06-30', 'New', 'Approved', '2026-07-12', 'LC07', 'Pulo Verde', 'ACQ-45492-26', '2026-03-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00590', 1, 'Identity', 'DOC-427594', '2026-06-30', 'Accepted', '2026-07-02', NULL),
('APP-2026-00590', 2, 'Registration', 'FILE-416576', '2026-07-04', 'Accepted', '2026-07-06', NULL),
('APP-2026-00590', 3, 'Acquisition', 'ACQ-45492-26', '2026-07-03', 'Accepted', '2026-07-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000583', 'APP-2026-00590', '2026-07-07', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00422', 'APP-2026-00590', '2026-07-17', '2026-07-17', '2027-07-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00591', 'AP-00098', 'GF-00107', '2026-07-01', 'New', 'Approved', '2026-08-28', 'LC02', 'San Isidro Heights', 'ACQ-72216-26', '2026-05-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00591', 1, 'Identity', 'DOC-912706', '2026-07-01', 'Accepted', '2026-07-05', NULL),
('APP-2026-00591', 2, 'Registration', 'DOC-776438', '2026-07-04', 'Accepted', '2026-07-07', NULL),
('APP-2026-00591', 3, 'Acquisition', 'ACQ-72216-26', '2026-07-05', 'Accepted', '2026-07-10', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00423', 'APP-2026-00591', '2026-09-01', '2026-09-01', '2027-08-31', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00592', 'AP-00164', 'GF-00046', '2026-07-01', 'New', 'Approved', '2026-07-21', 'LC03', 'Mabini East', 'ACQ-72121-26', '2026-06-05', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00592', 1, 'Identity', 'FILE-438698', '2026-07-01', 'Accepted', '2026-07-03', NULL),
('APP-2026-00592', 2, 'Registration', 'FILE-942898', '2026-07-03', 'Accepted', '2026-07-09', NULL),
('APP-2026-00592', 3, 'Acquisition', 'ACQ-72121-26', '2026-07-01', 'Accepted', '2026-07-02', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00424', 'APP-2026-00592', '2026-07-22', '2026-07-22', '2027-07-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00593', 'AP-00081', 'GF-00163', '2026-07-01', 'New', 'Approved', '2026-07-09', 'LC02', 'San Isidro Heights', 'ACQ-24241-26', '2026-03-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00593', 1, 'Identity', 'DOC-985236', '2026-07-01', 'Accepted', '2026-07-04', NULL),
('APP-2026-00593', 2, 'Registration', 'REF-950930', '2026-07-04', 'Accepted', '2026-07-06', NULL),
('APP-2026-00593', 3, 'Acquisition', 'ACQ-24241-26', '2026-07-06', 'Accepted', '2026-07-09', NULL),
('APP-2026-00593', 4, 'Other', 'REF-386522', '2026-07-04', 'Accepted', '2026-07-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000584', 'APP-2026-00593', '2026-07-04', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00425', 'APP-2026-00593', '2026-07-12', '2026-07-12', '2027-07-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00594', 'AP-00071', 'GF-00112', '2026-07-02', 'New', 'Approved', '2026-08-11', 'LC07', 'Pulo Verde', 'ACQ-95682-26', '2026-06-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00594', 1, 'Identity', 'FILE-278611', '2026-07-02', 'Accepted', '2026-07-06', NULL),
('APP-2026-00594', 2, 'Registration', 'FILE-260803', '2026-07-07', 'Accepted', '2026-07-13', NULL),
('APP-2026-00594', 3, 'Acquisition', 'ACQ-95682-26', '2026-07-02', 'Accepted', '2026-07-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000585', 'APP-2026-00594', '2026-07-05', 600, 'Cash'),
('OR-2026-000586', 'APP-2026-00594', '2026-07-03', 150, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00426', 'APP-2026-00594', '2026-08-16', '2026-08-16', '2027-08-15', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00595', 'AP-00082', 'GF-00156', '2026-07-03', 'Renewal', 'Approved', '2026-08-05', 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00129', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00595', 1, 'Identity', 'FILE-468594', '2026-07-03', 'Accepted', '2026-07-09', NULL),
('APP-2026-00595', 2, 'Registration', 'DOC-219992', '2026-07-04', 'Accepted', '2026-07-10', NULL),
('APP-2026-00595', 3, 'PriorPermit', 'PM-2025-00129', '2026-07-06', 'Accepted', '2026-07-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000587', 'APP-2026-00595', '2026-07-06', 600, 'BankTransfer'),
('OR-2026-000588', 'APP-2026-00595', '2026-07-03', 200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00427', 'APP-2026-00595', '2026-08-06', '2026-08-06', '2027-08-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00596', 'AP-00084', 'GF-00121', '2026-07-05', 'New', 'Approved', '2026-07-18', 'LC03', 'Mabini East', 'ACQ-66222-26', '2026-06-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00596', 1, 'Identity', 'DOC-162406', '2026-07-05', 'Accepted', '2026-07-11', NULL),
('APP-2026-00596', 2, 'Registration', 'DOC-143020', '2026-07-06', 'Accepted', '2026-07-13', NULL),
('APP-2026-00596', 3, 'Acquisition', 'ACQ-66222-26', '2026-07-05', 'Accepted', '2026-07-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000589', 'APP-2026-00596', '2026-07-12', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00428', 'APP-2026-00596', '2026-07-21', '2026-07-21', '2027-07-20', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00597', 'AP-00119', 'GF-00152', '2026-07-06', 'Renewal', 'Approved', '2026-07-16', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00224', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00597', 1, 'Identity', 'DOC-996431', '2026-07-06', 'Accepted', '2026-07-10', NULL),
('APP-2026-00597', 2, 'Registration', 'DOC-161315', '2026-07-11', 'Accepted', '2026-07-15', NULL),
('APP-2026-00597', 3, 'PriorPermit', 'PM-2025-00224', '2026-07-09', 'Accepted', '2026-07-13', NULL),
('APP-2026-00597', 4, 'Other', 'FILE-979448', '2026-07-08', 'Accepted', '2026-07-09', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000590', 'APP-2026-00597', '2026-07-06', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00429', 'APP-2026-00597', '2026-07-19', '2026-07-19', '2027-07-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00598', 'AP-00017', 'GF-00117', '2026-07-09', 'New', 'Approved', '2026-07-17', 'LC03', 'Mabini East', 'ACQ-36810-26', '2026-04-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00598', 1, 'Identity', 'REF-898358', '2026-07-09', 'Accepted', '2026-07-12', NULL),
('APP-2026-00598', 2, 'Registration', 'DOC-722767', '2026-07-10', 'Accepted', '2026-07-11', NULL),
('APP-2026-00598', 3, 'Acquisition', 'ACQ-36810-26', '2026-07-10', 'Accepted', '2026-07-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000591', 'APP-2026-00598', '2026-07-17', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00430', 'APP-2026-00598', '2026-07-17', '2026-07-17', '2027-07-16', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00599', 'AP-00163', 'GF-00159', '2026-07-09', 'Replacement', 'Rejected', '2026-08-20', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2026-06-20', 'IR-2026-5498');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00599', 1, 'Identity', 'DOC-193212', '2026-07-09', 'Accepted', '2026-07-11', NULL),
('APP-2026-00599', 2, 'Registration', 'DOC-632324', '2026-07-10', 'Pending', NULL, NULL),
('APP-2026-00599', 3, 'Incident', 'IR-2026-5498', '2026-07-14', 'Accepted', '2026-07-18', NULL),
('APP-2026-00599', 4, 'Other', 'FILE-941022', '2026-07-11', 'Accepted', '2026-07-18', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00600', 'AP-00097', 'GF-00137', '2026-07-10', 'New', 'Approved', '2026-07-31', 'LC05', 'Santa Elena', 'ACQ-97764-26', '2026-06-12', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00600', 1, 'Identity', 'REF-591123', '2026-07-10', 'Accepted', '2026-07-14', NULL),
('APP-2026-00600', 2, 'Registration', 'DOC-985810', '2026-07-15', 'Accepted', '2026-07-20', NULL),
('APP-2026-00600', 3, 'Acquisition', 'ACQ-97764-26', '2026-07-14', 'Accepted', '2026-07-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000592', 'APP-2026-00600', '2026-07-21', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00431', 'APP-2026-00600', '2026-08-02', '2026-08-02', '2027-08-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00601', 'AP-00109', 'GF-00023', '2026-07-10', 'Renewal', 'Approved', '2026-07-26', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00248', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00601', 1, 'Identity', 'FILE-563273', '2026-07-10', 'Accepted', '2026-07-14', NULL),
('APP-2026-00601', 2, 'Registration', 'FILE-842188', '2026-07-12', 'Accepted', '2026-07-16', NULL),
('APP-2026-00601', 3, 'PriorPermit', 'PM-2025-00248', '2026-07-12', 'Accepted', '2026-07-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000593', 'APP-2026-00601', '2026-07-10', 750, 'Cash'),
('OR-2026-000594', 'APP-2026-00601', '2026-07-13', 150, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00432', 'APP-2026-00601', '2026-07-29', '2026-07-29', '2027-07-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00602', 'AP-00049', 'GF-00113', '2026-07-10', 'Renewal', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00207', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00602', 1, 'Identity', 'REF-666078', '2026-07-10', 'NeedsCorrection', '2026-07-17', 'Please provide the missing page of the supporting document.'),
('APP-2026-00602', 2, 'Registration', 'DOC-595143', '2026-07-14', 'Pending', NULL, NULL),
('APP-2026-00602', 3, 'PriorPermit', 'PM-2025-00207', '2026-07-11', 'Accepted', '2026-07-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000595', 'APP-2026-00602', '2026-07-17', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00603', 'AP-00012', 'GF-00039', '2026-07-11', 'New', 'Approved', '2026-07-15', 'LC01', 'Luntian Central', 'ACQ-19341-26', '2026-03-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00603', 1, 'Identity', 'FILE-866270', '2026-07-11', 'Accepted', '2026-07-15', NULL),
('APP-2026-00603', 2, 'Registration', 'DOC-296314', '2026-07-12', 'Accepted', '2026-07-15', NULL),
('APP-2026-00603', 3, 'Acquisition', 'ACQ-19341-26', '2026-07-12', 'Accepted', '2026-07-15', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000596', 'APP-2026-00603', '2026-07-15', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00433', 'APP-2026-00603', '2026-07-18', '2026-07-18', '2027-07-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00604', 'AP-00176', 'GF-00004', '2026-07-13', 'New', 'Rejected', '2026-07-18', 'LC04', 'Bagong Silangan', 'ACQ-44453-26', '2026-05-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00604', 1, 'Identity', 'REF-398437', '2026-07-13', 'Pending', NULL, NULL),
('APP-2026-00604', 2, 'Registration', 'DOC-376491', '2026-07-15', 'NeedsCorrection', '2026-07-16', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00604', 3, 'Acquisition', 'ACQ-44453-26', '2026-07-16', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00605', 'AP-00100', 'GF-00084', '2026-07-14', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-54036-26', '2026-05-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00605', 1, 'Identity', 'REF-320284', '2026-07-14', 'Accepted', '2026-07-18', NULL),
('APP-2026-00605', 2, 'Registration', 'DOC-395978', '2026-07-17', 'Accepted', '2026-07-23', NULL),
('APP-2026-00605', 3, 'Acquisition', 'ACQ-54036-26', '2026-07-15', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000597', 'APP-2026-00605', '2026-07-23', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00606', 'AP-00110', 'GF-00136', '2026-07-14', 'New', 'Approved', '2026-08-02', 'LC04', 'Bagong Silangan', 'ACQ-86634-26', '2026-06-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00606', 1, 'Identity', 'DOC-870383', '2026-07-14', 'Accepted', '2026-07-18', NULL),
('APP-2026-00606', 2, 'Registration', 'DOC-393265', '2026-07-17', 'Accepted', '2026-07-24', NULL),
('APP-2026-00606', 3, 'Acquisition', 'ACQ-86634-26', '2026-07-19', 'Accepted', '2026-07-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000598', 'APP-2026-00606', '2026-07-26', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00434', 'APP-2026-00606', '2026-08-07', '2026-08-07', '2027-08-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00607', 'AP-00187', 'GF-00078', '2026-07-14', 'Renewal', 'Approved', '2026-07-20', 'LC06', 'Maligaya', NULL, NULL, 'PM-2025-00177', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00607', 1, 'Identity', 'FILE-578815', '2026-07-14', 'Accepted', '2026-07-19', NULL),
('APP-2026-00607', 2, 'Registration', 'FILE-637370', '2026-07-17', 'Accepted', '2026-07-20', NULL),
('APP-2026-00607', 3, 'PriorPermit', 'PM-2025-00177', '2026-07-15', 'Accepted', '2026-07-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000599', 'APP-2026-00607', '2026-07-18', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00435', 'APP-2026-00607', '2026-07-20', '2026-07-20', '2027-07-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00608', 'AP-00026', 'GF-00161', '2026-07-15', 'New', 'Rejected', '2026-07-26', 'LC03', 'Mabini East', 'ACQ-39983-26', '2026-05-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00608', 1, 'Identity', 'FILE-845269', '2026-07-15', 'NeedsCorrection', '2026-07-17', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00608', 2, 'Registration', 'FILE-940394', '2026-07-15', 'NeedsCorrection', '2026-07-20', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00608', 3, 'Acquisition', 'ACQ-39983-26', '2026-07-15', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000600', 'APP-2026-00608', '2026-07-16', 600, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00609', 'AP-00187', 'GF-00127', '2026-07-15', 'New', 'Approved', '2026-08-06', 'LC06', 'Maligaya', 'ACQ-99048-26', '2026-03-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00609', 1, 'Identity', 'REF-520818', '2026-07-15', 'Accepted', '2026-07-22', NULL),
('APP-2026-00609', 2, 'Registration', 'FILE-888768', '2026-07-15', 'Accepted', '2026-07-16', NULL),
('APP-2026-00609', 3, 'Acquisition', 'ACQ-99048-26', '2026-07-16', 'Accepted', '2026-07-20', NULL);


INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00436', 'APP-2026-00609', '2026-08-07', '2026-08-07', '2027-08-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00610', 'AP-00121', 'GF-00132', '2026-07-16', 'Renewal', 'Approved', '2026-07-23', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00077', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00610', 1, 'Identity', 'REF-804848', '2026-07-16', 'Accepted', '2026-07-17', NULL),
('APP-2026-00610', 2, 'Registration', 'DOC-69983', '2026-07-18', 'Accepted', '2026-07-22', NULL),
('APP-2026-00610', 3, 'PriorPermit', 'PM-2025-00077', '2026-07-19', 'Accepted', '2026-07-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000601', 'APP-2026-00610', '2026-07-22', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00437', 'APP-2026-00610', '2026-07-25', '2026-07-25', '2027-07-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00611', 'AP-00070', 'GF-00091', '2026-07-17', 'New', 'Approved', '2026-08-08', 'LC01', 'Luntian Central', 'ACQ-11469-26', '2026-06-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00611', 1, 'Identity', 'REF-675322', '2026-07-17', 'Accepted', '2026-07-20', NULL),
('APP-2026-00611', 2, 'Registration', 'REF-741941', '2026-07-21', 'Accepted', '2026-07-27', NULL),
('APP-2026-00611', 3, 'Acquisition', 'ACQ-11469-26', '2026-07-21', 'Accepted', '2026-07-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000602', 'APP-2026-00611', '2026-07-28', 900, 'Cash'),
('OR-2026-000603', 'APP-2026-00611', '2026-07-26', 250, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00438', 'APP-2026-00611', '2026-08-09', '2026-08-09', '2027-08-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00612', 'AP-00082', 'GF-00081', '2026-07-18', 'Replacement', 'Submitted', NULL, 'LC07', 'Pulo Verde', NULL, NULL, NULL, NULL, '2026-07-14', 'IR-2026-5390');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00612', 1, 'Identity', 'DOC-793836', '2026-07-18', 'Pending', NULL, NULL),
('APP-2026-00612', 2, 'Registration', 'DOC-278698', '2026-07-20', 'Pending', NULL, NULL),
('APP-2026-00612', 3, 'Incident', 'IR-2026-5390', '2026-07-20', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000604', 'APP-2026-00612', '2026-07-24', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00613', 'AP-00039', 'GF-00017', '2026-07-19', 'New', 'Approved', '2026-08-09', 'LC01', 'Luntian Central', 'ACQ-28121-26', '2026-05-04', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00613', 1, 'Identity', 'REF-628305', '2026-07-19', 'Accepted', '2026-07-22', NULL),
('APP-2026-00613', 2, 'Registration', 'REF-414488', '2026-07-22', 'Accepted', '2026-07-27', NULL),
('APP-2026-00613', 3, 'Acquisition', 'ACQ-28121-26', '2026-07-23', 'Accepted', '2026-07-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000605', 'APP-2026-00613', '2026-07-25', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00439', 'APP-2026-00613', '2026-08-09', '2026-08-09', '2027-08-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00614', 'AP-00149', 'GF-00063', '2026-07-19', 'New', 'Approved', '2026-09-08', 'LC01', 'Luntian Central', 'ACQ-19662-26', '2026-05-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00614', 1, 'Identity', 'REF-44871', '2026-07-19', 'Accepted', '2026-07-24', NULL),
('APP-2026-00614', 2, 'Registration', 'REF-74757', '2026-07-21', 'Accepted', '2026-07-23', NULL),
('APP-2026-00614', 3, 'Acquisition', 'ACQ-19662-26', '2026-07-21', 'Accepted', '2026-07-25', NULL),
('APP-2026-00614', 4, 'Other', 'FILE-979398', '2026-07-24', 'Accepted', '2026-07-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000606', 'APP-2026-00614', '2026-07-20', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00440', 'APP-2026-00614', '2026-09-08', '2026-09-08', '2027-09-07', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00615', 'AP-00167', 'GF-00063', '2026-07-19', 'New', 'Approved', '2026-08-12', 'LC01', 'Luntian Central', 'ACQ-83314-26', '2026-07-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00615', 1, 'Identity', 'DOC-385889', '2026-07-19', 'Accepted', '2026-07-21', NULL),
('APP-2026-00615', 2, 'Registration', 'FILE-348474', '2026-07-22', 'Accepted', '2026-07-26', NULL),
('APP-2026-00615', 3, 'Acquisition', 'ACQ-83314-26', '2026-07-21', 'Accepted', '2026-07-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000607', 'APP-2026-00615', '2026-07-19', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00441', 'APP-2026-00615', '2026-08-12', '2026-08-12', '2027-08-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00616', 'AP-00015', 'GF-00130', '2026-07-19', 'Renewal', 'Approved', '2026-08-06', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00093', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00616', 1, 'Identity', 'DOC-604488', '2026-07-19', 'Accepted', '2026-07-24', NULL),
('APP-2026-00616', 2, 'Registration', 'REF-77291', '2026-07-21', 'Accepted', '2026-07-22', NULL),
('APP-2026-00616', 3, 'PriorPermit', 'PM-2025-00093', '2026-07-24', 'Accepted', '2026-07-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000608', 'APP-2026-00616', '2026-07-21', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00442', 'APP-2026-00616', '2026-08-09', '2026-08-09', '2027-08-08', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00617', 'AP-00188', 'GF-00036', '2026-07-20', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-85376-26', '2026-05-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00617', 1, 'Identity', 'REF-697794', '2026-07-20', 'Pending', NULL, NULL),
('APP-2026-00617', 2, 'Registration', 'DOC-755613', '2026-07-20', 'Accepted', '2026-07-27', NULL),
('APP-2026-00617', 3, 'Acquisition', 'ACQ-85376-26', '2026-07-23', 'Accepted', '2026-07-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000609', 'APP-2026-00617', '2026-07-27', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00618', 'AP-00087', 'GF-00038', '2026-07-21', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-27830-26', '2026-04-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00618', 1, 'Identity', 'REF-836170', '2026-07-21', 'NeedsCorrection', '2026-07-28', 'The date on the document needs clarification.'),
('APP-2026-00618', 2, 'Registration', 'FILE-856395', '2026-07-21', 'Pending', NULL, NULL),
('APP-2026-00618', 3, 'Acquisition', 'ACQ-27830-26', '2026-07-25', 'Accepted', '2026-07-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000610', 'APP-2026-00618', '2026-07-26', 900, 'Online'),
('OR-2026-000611', 'APP-2026-00618', '2026-08-02', 250, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00619', 'AP-00039', 'GF-00105', '2026-07-22', 'Renewal', 'Rejected', '2026-08-15', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00203', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00619', 1, 'Identity', 'FILE-974326', '2026-07-22', 'NeedsCorrection', '2026-07-23', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00619', 2, 'Registration', 'REF-535874', '2026-07-27', 'Pending', NULL, NULL),
('APP-2026-00619', 3, 'PriorPermit', 'PM-2025-00203', '2026-07-26', 'Accepted', '2026-07-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000612', 'APP-2026-00619', '2026-08-01', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00620', 'AP-00089', 'GF-00031', '2026-07-23', 'New', 'Approved', '2026-08-15', 'LC01', 'Luntian Central', 'ACQ-11879-26', '2026-07-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00620', 1, 'Identity', 'REF-125320', '2026-07-23', 'Accepted', '2026-07-27', NULL),
('APP-2026-00620', 2, 'Registration', 'REF-890825', '2026-07-28', 'Accepted', '2026-07-31', NULL),
('APP-2026-00620', 3, 'Acquisition', 'ACQ-11879-26', '2026-07-25', 'Accepted', '2026-07-30', NULL),
('APP-2026-00620', 4, 'Other', 'REF-379367', '2026-07-27', 'Accepted', '2026-07-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000613', 'APP-2026-00620', '2026-08-01', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00443', 'APP-2026-00620', '2026-08-20', '2026-08-20', '2027-08-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00621', 'AP-00121', 'GF-00094', '2026-07-24', 'New', 'Approved', '2026-09-16', 'LC02', 'San Isidro Heights', 'ACQ-74665-26', '2026-06-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00621', 1, 'Identity', 'REF-871130', '2026-07-24', 'Accepted', '2026-07-29', NULL),
('APP-2026-00621', 2, 'Registration', 'DOC-571618', '2026-07-25', 'Accepted', '2026-07-26', NULL),
('APP-2026-00621', 3, 'Acquisition', 'ACQ-74665-26', '2026-07-26', 'Accepted', '2026-08-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000614', 'APP-2026-00621', '2026-07-28', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00444', 'APP-2026-00621', '2026-09-19', '2026-09-19', '2027-09-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00622', 'AP-00084', 'GF-00113', '2026-07-24', 'New', 'Approved', '2026-08-02', 'LC03', 'Mabini East', 'ACQ-54318-26', '2026-06-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00622', 1, 'Identity', 'FILE-614643', '2026-07-24', 'Accepted', '2026-07-27', NULL),
('APP-2026-00622', 2, 'Registration', 'FILE-397324', '2026-07-24', 'Accepted', '2026-07-26', NULL),
('APP-2026-00622', 3, 'Acquisition', 'ACQ-54318-26', '2026-07-27', 'Accepted', '2026-07-28', NULL),
('APP-2026-00622', 4, 'Other', 'DOC-579050', '2026-07-29', 'Accepted', '2026-08-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000615', 'APP-2026-00622', '2026-07-25', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00445', 'APP-2026-00622', '2026-08-02', '2026-08-02', '2027-08-01', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00623', 'AP-00190', 'GF-00016', '2026-07-24', 'Renewal', 'Rejected', '2026-08-01', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2024-00016', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00623', 1, 'Identity', 'DOC-968854', '2026-07-24', 'Accepted', '2026-07-25', NULL),
('APP-2026-00623', 2, 'Registration', 'FILE-675161', '2026-07-24', 'Accepted', '2026-07-30', NULL),
('APP-2026-00623', 3, 'PriorPermit', 'PM-2024-00016', '2026-07-28', 'Accepted', '2026-08-01', NULL),
('APP-2026-00623', 4, 'Other', 'DOC-380079', '2026-07-27', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00624', 'AP-00186', 'GF-00078', '2026-07-25', 'Replacement', 'Approved', '2026-08-13', 'LC04', 'Bagong Silangan', NULL, NULL, NULL, NULL, '2026-07-18', 'IR-2026-8746');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00624', 1, 'Identity', 'DOC-925530', '2026-07-25', 'Accepted', '2026-07-28', NULL),
('APP-2026-00624', 2, 'Registration', 'DOC-345648', '2026-07-28', 'Accepted', '2026-08-01', NULL),
('APP-2026-00624', 3, 'Incident', 'IR-2026-8746', '2026-07-26', 'Accepted', '2026-08-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000616', 'APP-2026-00624', '2026-07-28', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00446', 'APP-2026-00624', '2026-08-18', '2026-08-18', '2027-08-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00625', 'AP-00085', 'GF-00017', '2026-07-27', 'New', 'Approved', '2026-08-15', 'LC03', 'Mabini East', 'ACQ-59642-26', '2026-06-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00625', 1, 'Identity', 'DOC-475433', '2026-07-27', 'Accepted', '2026-08-01', NULL),
('APP-2026-00625', 2, 'Registration', 'REF-725721', '2026-07-29', 'Accepted', '2026-07-31', NULL),
('APP-2026-00625', 3, 'Acquisition', 'ACQ-59642-26', '2026-07-29', 'Accepted', '2026-08-02', NULL),
('APP-2026-00625', 4, 'Other', 'REF-474148', '2026-08-01', 'Accepted', '2026-08-04', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000617', 'APP-2026-00625', '2026-07-30', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00447', 'APP-2026-00625', '2026-08-18', '2026-08-18', '2027-08-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00626', 'AP-00067', 'GF-00051', '2026-07-29', 'Replacement', 'Approved', '2026-08-08', 'LC04', 'Bagong Silangan', NULL, NULL, NULL, NULL, '2026-07-28', 'IR-2026-9467');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00626', 1, 'Identity', 'REF-429225', '2026-07-29', 'Accepted', '2026-08-01', NULL),
('APP-2026-00626', 2, 'Registration', 'FILE-173984', '2026-08-02', 'Accepted', '2026-08-08', NULL),
('APP-2026-00626', 3, 'Incident', 'IR-2026-9467', '2026-07-29', 'Accepted', '2026-08-03', NULL),
('APP-2026-00626', 4, 'Other', 'DOC-722382', '2026-08-01', 'Accepted', '2026-08-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000618', 'APP-2026-00626', '2026-08-08', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00448', 'APP-2026-00626', '2026-08-12', '2026-08-12', '2027-08-11', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00627', 'AP-00007', 'GF-00143', '2026-07-30', 'New', 'Approved', '2026-08-24', 'LC01', 'Luntian Central', 'ACQ-72331-26', '2026-07-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00627', 1, 'Identity', 'REF-677694', '2026-07-30', 'Accepted', '2026-08-04', NULL),
('APP-2026-00627', 2, 'Registration', 'REF-35577', '2026-08-02', 'Accepted', '2026-08-06', NULL),
('APP-2026-00627', 3, 'Acquisition', 'ACQ-72331-26', '2026-08-01', 'Accepted', '2026-08-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000619', 'APP-2026-00627', '2026-08-11', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00449', 'APP-2026-00627', '2026-08-27', '2026-08-27', '2027-08-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00628', 'AP-00180', 'GF-00076', '2026-08-03', 'New', 'Approved', '2026-08-07', 'LC07', 'Pulo Verde', 'ACQ-98076-26', '2026-04-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00628', 1, 'Identity', 'REF-162729', '2026-08-03', 'Accepted', '2026-08-07', NULL),
('APP-2026-00628', 2, 'Registration', 'FILE-944213', '2026-08-03', 'Accepted', '2026-08-07', NULL),
('APP-2026-00628', 3, 'Acquisition', 'ACQ-98076-26', '2026-08-04', 'Accepted', '2026-08-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000620', 'APP-2026-00628', '2026-08-07', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00450', 'APP-2026-00628', '2026-08-10', '2026-08-10', '2027-08-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00629', 'AP-00083', 'GF-00046', '2026-08-03', 'New', 'Approved', '2026-08-08', 'LC08', 'San Rafael Norte', 'ACQ-31504-26', '2026-05-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00629', 1, 'Identity', 'FILE-52339', '2026-08-03', 'Accepted', '2026-08-07', NULL),
('APP-2026-00629', 2, 'Registration', 'REF-534407', '2026-08-03', 'Accepted', '2026-08-08', NULL),
('APP-2026-00629', 3, 'Acquisition', 'ACQ-31504-26', '2026-08-07', 'Accepted', '2026-08-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000621', 'APP-2026-00629', '2026-08-08', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00451', 'APP-2026-00629', '2026-08-10', '2026-08-10', '2027-08-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00630', 'AP-00164', 'GF-00107', '2026-08-03', 'Renewal', 'Approved', '2026-08-16', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00219', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00630', 1, 'Identity', 'DOC-889412', '2026-08-03', 'Accepted', '2026-08-10', NULL),
('APP-2026-00630', 2, 'Registration', 'DOC-480190', '2026-08-07', 'Accepted', '2026-08-08', NULL),
('APP-2026-00630', 3, 'PriorPermit', 'PM-2025-00219', '2026-08-05', 'Accepted', '2026-08-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000622', 'APP-2026-00630', '2026-08-12', 350, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00452', 'APP-2026-00630', '2026-08-19', '2026-08-19', '2027-08-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00631', 'AP-00153', 'GF-00030', '2026-08-04', 'New', 'Approved', '2026-08-15', 'LC06', 'Maligaya', 'ACQ-78776-26', '2026-06-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00631', 1, 'Identity', 'REF-822077', '2026-08-04', 'Accepted', '2026-08-11', NULL),
('APP-2026-00631', 2, 'Registration', 'REF-429937', '2026-08-07', 'Accepted', '2026-08-11', NULL),
('APP-2026-00631', 3, 'Acquisition', 'ACQ-78776-26', '2026-08-04', 'Accepted', '2026-08-11', NULL),
('APP-2026-00631', 4, 'Other', 'REF-949227', '2026-08-06', 'Accepted', '2026-08-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000623', 'APP-2026-00631', '2026-08-09', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00453', 'APP-2026-00631', '2026-08-18', '2026-08-18', '2027-08-17', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00632', 'AP-00181', 'GF-00141', '2026-08-04', 'Renewal', 'Submitted', NULL, 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00037', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00632', 1, 'Identity', 'DOC-890286', '2026-08-04', 'Pending', NULL, NULL),
('APP-2026-00632', 2, 'Registration', 'FILE-546318', '2026-08-08', 'Pending', NULL, NULL),
('APP-2026-00632', 3, 'PriorPermit', 'PM-2025-00037', '2026-08-04', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000624', 'APP-2026-00632', '2026-08-11', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00633', 'AP-00002', 'GF-00016', '2026-08-07', 'New', 'Approved', '2026-08-13', 'LC07', 'Pulo Verde', 'ACQ-11672-26', '2026-04-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00633', 1, 'Identity', 'DOC-49218', '2026-08-07', 'Accepted', '2026-08-12', NULL),
('APP-2026-00633', 2, 'Registration', 'DOC-130425', '2026-08-10', 'Accepted', '2026-08-13', NULL),
('APP-2026-00633', 3, 'Acquisition', 'ACQ-11672-26', '2026-08-07', 'Accepted', '2026-08-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000625', 'APP-2026-00633', '2026-08-13', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00454', 'APP-2026-00633', '2026-08-14', '2026-08-14', '2027-08-13', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00634', 'AP-00074', 'GF-00003', '2026-08-11', 'New', 'Rejected', '2026-08-20', 'LC02', 'San Isidro Heights', 'ACQ-49321-26', '2026-04-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00634', 1, 'Identity', 'REF-435269', '2026-08-11', 'Pending', NULL, NULL),
('APP-2026-00634', 2, 'Registration', 'FILE-425701', '2026-08-14', 'Pending', NULL, NULL),
('APP-2026-00634', 3, 'Acquisition', 'ACQ-49321-26', '2026-08-15', 'Accepted', '2026-08-17', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00635', 'AP-00024', 'GF-00104', '2026-08-11', 'New', 'Approved', '2026-09-24', 'LC06', 'Maligaya', 'ACQ-24953-26', '2026-05-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00635', 1, 'Identity', 'REF-505919', '2026-08-11', 'Accepted', '2026-08-17', NULL),
('APP-2026-00635', 2, 'Registration', 'REF-36817', '2026-08-11', 'Accepted', '2026-08-13', NULL),
('APP-2026-00635', 3, 'Acquisition', 'ACQ-24953-26', '2026-08-16', 'Accepted', '2026-08-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000626', 'APP-2026-00635', '2026-08-13', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00636', 'AP-00035', 'GF-00019', '2026-08-11', 'New', 'Withdrawn', NULL, 'LC08', 'San Rafael Norte', 'ACQ-50564-26', '2026-06-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00636', 1, 'Identity', 'DOC-536830', '2026-08-11', 'Accepted', '2026-08-14', NULL),
('APP-2026-00636', 2, 'Registration', 'REF-308282', '2026-08-14', 'NeedsCorrection', '2026-08-19', 'Please provide the missing page of the supporting document.'),
('APP-2026-00636', 3, 'Acquisition', 'ACQ-50564-26', '2026-08-11', 'Accepted', '2026-08-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000627', 'APP-2026-00636', '2026-08-11', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00637', 'AP-00150', 'GF-00069', '2026-08-11', 'New', 'Approved', '2026-08-19', 'LC04', 'Bagong Silangan', 'ACQ-33578-26', '2026-05-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00637', 1, 'Identity', 'REF-51834', '2026-08-11', 'Accepted', '2026-08-13', NULL),
('APP-2026-00637', 2, 'Registration', 'REF-815164', '2026-08-14', 'Accepted', '2026-08-16', NULL),
('APP-2026-00637', 3, 'Acquisition', 'ACQ-33578-26', '2026-08-11', 'Accepted', '2026-08-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000628', 'APP-2026-00637', '2026-08-19', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00455', 'APP-2026-00637', '2026-08-20', '2026-08-20', '2027-08-19', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00638', 'AP-00006', 'GF-00042', '2026-08-11', 'Renewal', 'Rejected', '2026-08-20', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00030', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00638', 1, 'Identity', 'REF-759828', '2026-08-11', 'Accepted', '2026-08-14', NULL),
('APP-2026-00638', 2, 'Registration', 'DOC-638860', '2026-08-12', 'NeedsCorrection', '2026-08-13', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00638', 3, 'PriorPermit', 'PM-2025-00030', '2026-08-12', 'Accepted', '2026-08-13', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000629', 'APP-2026-00638', '2026-08-20', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00639', 'AP-00114', 'GF-00109', '2026-08-13', 'New', 'Approved', '2026-08-27', 'LC01', 'Luntian Central', 'ACQ-48560-26', '2026-07-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00639', 1, 'Identity', 'DOC-916011', '2026-08-13', 'Accepted', '2026-08-20', NULL),
('APP-2026-00639', 2, 'Registration', 'REF-645606', '2026-08-13', 'Accepted', '2026-08-17', NULL),
('APP-2026-00639', 3, 'Acquisition', 'ACQ-48560-26', '2026-08-13', 'Accepted', '2026-08-17', NULL),
('APP-2026-00639', 4, 'Other', 'DOC-916709', '2026-08-18', 'Accepted', '2026-08-21', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000630', 'APP-2026-00639', '2026-08-16', 600, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00456', 'APP-2026-00639', '2026-08-28', '2026-08-28', '2027-08-27', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00640', 'AP-00057', 'GF-00142', '2026-08-14', 'New', 'Approved', '2026-08-25', 'LC03', 'Mabini East', 'ACQ-45467-26', '2026-04-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00640', 1, 'Identity', 'DOC-13098', '2026-08-14', 'Accepted', '2026-08-18', NULL),
('APP-2026-00640', 2, 'Registration', 'DOC-753320', '2026-08-16', 'Accepted', '2026-08-23', NULL),
('APP-2026-00640', 3, 'Acquisition', 'ACQ-45467-26', '2026-08-17', 'Accepted', '2026-08-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000631', 'APP-2026-00640', '2026-08-19', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00457', 'APP-2026-00640', '2026-08-30', '2026-08-30', '2027-08-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00641', 'AP-00146', 'GF-00148', '2026-08-15', 'Replacement', 'Approved', '2026-09-19', 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2026-08-06', 'IR-2026-1958');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00641', 1, 'Identity', 'FILE-400072', '2026-08-15', 'Accepted', '2026-08-17', NULL),
('APP-2026-00641', 2, 'Registration', 'FILE-19319', '2026-08-15', 'Accepted', '2026-08-17', NULL),
('APP-2026-00641', 3, 'Incident', 'IR-2026-1958', '2026-08-16', 'Accepted', '2026-08-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000632', 'APP-2026-00641', '2026-08-16', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00458', 'APP-2026-00641', '2026-09-22', '2026-09-22', '2027-09-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00642', 'AP-00091', 'GF-00113', '2026-08-17', 'New', 'UnderReview', NULL, 'LC02', 'San Isidro Heights', 'ACQ-68322-26', '2026-07-03', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00642', 1, 'Identity', 'FILE-387313', '2026-08-17', 'Accepted', '2026-08-19', NULL),
('APP-2026-00642', 2, 'Registration', 'FILE-413098', '2026-08-22', 'Accepted', '2026-08-29', NULL),
('APP-2026-00642', 3, 'Acquisition', 'ACQ-68322-26', '2026-08-19', 'Accepted', '2026-08-25', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000633', 'APP-2026-00642', '2026-08-24', 600, 'Online'),
('OR-2026-000634', 'APP-2026-00642', '2026-08-25', 150, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00643', 'AP-00019', 'GF-00153', '2026-08-17', 'Renewal', 'Approved', '2026-08-20', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00155', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00643', 1, 'Identity', 'DOC-393604', '2026-08-17', 'Accepted', '2026-08-20', NULL),
('APP-2026-00643', 2, 'Registration', 'FILE-558068', '2026-08-20', 'Accepted', '2026-08-20', NULL),
('APP-2026-00643', 3, 'PriorPermit', 'PM-2025-00155', '2026-08-20', 'Accepted', '2026-08-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000635', 'APP-2026-00643', '2026-08-20', 750, 'BankTransfer'),
('OR-2026-000636', 'APP-2026-00643', '2026-08-20', 150, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00459', 'APP-2026-00643', '2026-08-22', '2026-08-22', '2027-08-21', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00644', 'AP-00097', 'GF-00050', '2026-08-19', 'New', 'Approved', '2026-08-27', 'LC05', 'Santa Elena', 'ACQ-70425-26', '2026-07-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00644', 1, 'Identity', 'FILE-733111', '2026-08-19', 'Accepted', '2026-08-23', NULL),
('APP-2026-00644', 2, 'Registration', 'DOC-681451', '2026-08-24', 'Accepted', '2026-08-27', NULL),
('APP-2026-00644', 3, 'Acquisition', 'ACQ-70425-26', '2026-08-21', 'Accepted', '2026-08-24', NULL),
('APP-2026-00644', 4, 'Other', 'REF-749146', '2026-08-23', 'Accepted', '2026-08-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000637', 'APP-2026-00644', '2026-08-21', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00460', 'APP-2026-00644', '2026-09-01', '2026-09-01', '2027-08-31', 'Suspended');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00645', 'AP-00149', 'GF-00031', '2026-08-20', 'New', 'UnderReview', NULL, 'LC01', 'Luntian Central', 'ACQ-66626-26', '2026-07-10', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00645', 1, 'Identity', 'DOC-842327', '2026-08-20', 'NeedsCorrection', '2026-08-27', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00645', 2, 'Registration', 'DOC-609127', '2026-08-22', 'NeedsCorrection', '2026-08-27', 'The submitted name requires clarification against the application.'),
('APP-2026-00645', 3, 'Acquisition', 'ACQ-66626-26', '2026-08-21', 'Accepted', '2026-08-27', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000638', 'APP-2026-00645', '2026-08-24', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00646', 'AP-00057', 'GF-00036', '2026-08-21', 'New', 'Approved', '2026-09-06', 'LC03', 'Mabini East', 'ACQ-65760-26', '2026-07-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00646', 1, 'Identity', 'DOC-249662', '2026-08-21', 'Accepted', '2026-08-22', NULL),
('APP-2026-00646', 2, 'Registration', 'REF-46002', '2026-08-22', 'Accepted', '2026-08-28', NULL),
('APP-2026-00646', 3, 'Acquisition', 'ACQ-65760-26', '2026-08-22', 'Accepted', '2026-08-23', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000639', 'APP-2026-00646', '2026-08-29', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00461', 'APP-2026-00646', '2026-09-10', '2026-09-10', '2027-09-09', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00647', 'AP-00110', 'GF-00084', '2026-08-24', 'New', 'Approved', '2026-09-13', 'LC04', 'Bagong Silangan', 'ACQ-59400-26', '2026-08-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00647', 1, 'Identity', 'REF-299211', '2026-08-24', 'Accepted', '2026-08-29', NULL),
('APP-2026-00647', 2, 'Registration', 'REF-949921', '2026-08-27', 'Accepted', '2026-09-01', NULL),
('APP-2026-00647', 3, 'Acquisition', 'ACQ-59400-26', '2026-08-28', 'Accepted', '2026-09-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000640', 'APP-2026-00647', '2026-08-28', 900, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00462', 'APP-2026-00647', '2026-09-17', '2026-09-17', '2027-09-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00648', 'AP-00181', 'GF-00005', '2026-08-24', 'Renewal', 'Approved', '2026-09-03', 'LC07', 'Pulo Verde', NULL, NULL, 'PM-2025-00174', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00648', 1, 'Identity', 'DOC-504172', '2026-08-24', 'Accepted', '2026-08-26', NULL),
('APP-2026-00648', 2, 'Registration', 'REF-469952', '2026-08-28', 'Accepted', '2026-09-02', NULL),
('APP-2026-00648', 3, 'PriorPermit', 'PM-2025-00174', '2026-08-27', 'Accepted', '2026-08-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000641', 'APP-2026-00648', '2026-08-28', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00463', 'APP-2026-00648', '2026-09-06', '2026-09-06', '2027-09-05', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00649', 'AP-00098', 'GF-00119', '2026-08-24', 'Replacement', 'Submitted', NULL, 'LC02', 'San Isidro Heights', NULL, NULL, NULL, NULL, '2026-08-10', 'IR-2026-9187');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00649', 1, 'Identity', 'FILE-99926', '2026-08-24', 'Pending', NULL, NULL),
('APP-2026-00649', 2, 'Registration', 'DOC-878606', '2026-08-26', 'Pending', NULL, NULL),
('APP-2026-00649', 3, 'Incident', 'IR-2026-9187', '2026-08-26', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00650', 'AP-00043', 'GF-00160', '2026-08-25', 'New', 'Approved', '2026-09-01', 'LC02', 'San Isidro Heights', 'ACQ-36691-26', '2026-07-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00650', 1, 'Identity', 'REF-659803', '2026-08-25', 'Accepted', '2026-08-31', NULL),
('APP-2026-00650', 2, 'Registration', 'REF-966578', '2026-08-25', 'Accepted', '2026-09-01', NULL),
('APP-2026-00650', 3, 'Acquisition', 'ACQ-36691-26', '2026-08-25', 'Accepted', '2026-08-28', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000642', 'APP-2026-00650', '2026-08-29', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00651', 'AP-00136', 'GF-00065', '2026-08-25', 'New', 'Approved', '2026-09-18', 'LC02', 'San Isidro Heights', 'ACQ-68105-26', '2026-07-08', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00651', 1, 'Identity', 'FILE-154825', '2026-08-25', 'Accepted', '2026-08-29', NULL),
('APP-2026-00651', 2, 'Registration', 'REF-306700', '2026-08-26', 'Accepted', '2026-08-29', NULL),
('APP-2026-00651', 3, 'Acquisition', 'ACQ-68105-26', '2026-08-25', 'Accepted', '2026-08-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000643', 'APP-2026-00651', '2026-08-26', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00464', 'APP-2026-00651', '2026-09-21', '2026-09-21', '2027-09-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00652', 'AP-00179', 'GF-00024', '2026-08-25', 'New', 'Withdrawn', NULL, 'LC02', 'San Isidro Heights', 'ACQ-13554-26', '2026-07-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00652', 1, 'Identity', 'DOC-78365', '2026-08-25', 'Pending', NULL, NULL),
('APP-2026-00652', 2, 'Registration', 'DOC-508129', '2026-08-27', 'Pending', NULL, NULL),
('APP-2026-00652', 3, 'Acquisition', 'ACQ-13554-26', '2026-08-25', 'Accepted', '2026-09-01', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00653', 'AP-00172', 'GF-00032', '2026-08-25', 'New', 'Rejected', '2026-09-19', 'LC06', 'Maligaya', 'ACQ-25747-26', '2026-06-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00653', 1, 'Identity', 'REF-579482', '2026-08-25', 'Accepted', '2026-08-28', NULL),
('APP-2026-00653', 2, 'Registration', 'DOC-605806', '2026-08-30', 'Accepted', '2026-09-01', NULL),
('APP-2026-00653', 3, 'Acquisition', 'ACQ-25747-26', '2026-08-25', 'NeedsCorrection', '2026-08-30', 'The submitted name requires clarification against the application.'),
('APP-2026-00653', 4, 'Other', 'DOC-827579', '2026-08-28', 'NeedsCorrection', '2026-09-03', 'Please provide the missing page of the supporting document.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000644', 'APP-2026-00653', '2026-08-26', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00654', 'AP-00128', 'GF-00100', '2026-08-28', 'Renewal', 'Approved', '2026-09-01', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00192', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00654', 1, 'Identity', 'REF-890650', '2026-08-28', 'Accepted', '2026-09-01', NULL),
('APP-2026-00654', 2, 'Registration', 'DOC-944858', '2026-09-01', 'Accepted', '2026-09-01', NULL),
('APP-2026-00654', 3, 'PriorPermit', 'PM-2025-00192', '2026-08-30', 'Accepted', '2026-09-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000645', 'APP-2026-00654', '2026-09-01', 600, 'Online'),
('OR-2026-000646', 'APP-2026-00654', '2026-08-28', 100, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00655', 'AP-00031', 'GF-00131', '2026-08-28', 'Renewal', 'Rejected', '2026-10-08', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00046', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00655', 1, 'Identity', 'DOC-149921', '2026-08-28', 'Accepted', '2026-08-31', NULL),
('APP-2026-00655', 2, 'Registration', 'FILE-707523', '2026-08-30', 'Accepted', '2026-09-06', NULL),
('APP-2026-00655', 3, 'PriorPermit', 'PM-2025-00046', '2026-08-29', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000647', 'APP-2026-00655', '2026-09-04', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00656', 'AP-00184', 'GF-00087', '2026-08-29', 'New', 'Approved', '2026-09-02', 'LC04', 'Bagong Silangan', 'ACQ-61326-26', '2026-07-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00656', 1, 'Identity', 'FILE-531839', '2026-08-29', 'Accepted', '2026-09-02', NULL),
('APP-2026-00656', 2, 'Registration', 'DOC-215079', '2026-09-02', 'Accepted', '2026-09-02', NULL),
('APP-2026-00656', 3, 'Acquisition', 'ACQ-61326-26', '2026-08-30', 'Accepted', '2026-09-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000648', 'APP-2026-00656', '2026-09-02', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00465', 'APP-2026-00656', '2026-09-03', '2026-09-03', '2027-09-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00657', 'AP-00094', 'GF-00084', '2026-08-29', 'Renewal', 'Approved', '2026-09-12', 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00103', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00657', 1, 'Identity', 'FILE-583133', '2026-08-29', 'Accepted', '2026-09-04', NULL),
('APP-2026-00657', 2, 'Registration', 'DOC-393263', '2026-09-03', 'Accepted', '2026-09-05', NULL),
('APP-2026-00657', 3, 'PriorPermit', 'PM-2025-00103', '2026-09-02', 'Accepted', '2026-09-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000649', 'APP-2026-00657', '2026-08-31', 350, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00466', 'APP-2026-00657', '2026-09-17', '2026-09-17', '2027-09-16', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00658', 'AP-00088', 'GF-00075', '2026-08-30', 'New', 'Approved', '2026-09-24', 'LC06', 'Maligaya', 'ACQ-70017-26', '2026-05-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00658', 1, 'Identity', 'FILE-455348', '2026-08-30', 'Accepted', '2026-08-31', NULL),
('APP-2026-00658', 2, 'Registration', 'DOC-697855', '2026-09-02', 'Accepted', '2026-09-09', NULL),
('APP-2026-00658', 3, 'Acquisition', 'ACQ-70017-26', '2026-09-02', 'Accepted', '2026-09-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000650', 'APP-2026-00658', '2026-09-10', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00467', 'APP-2026-00658', '2026-09-25', '2026-09-25', '2027-09-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00659', 'AP-00038', 'GF-00122', '2026-08-30', 'New', 'Approved', '2026-09-24', 'LC03', 'Mabini East', 'ACQ-72842-26', '2026-05-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00659', 1, 'Identity', 'REF-136165', '2026-08-30', 'Accepted', '2026-08-31', NULL),
('APP-2026-00659', 2, 'Registration', 'FILE-907363', '2026-08-30', 'Accepted', '2026-09-03', NULL),
('APP-2026-00659', 3, 'Acquisition', 'ACQ-72842-26', '2026-09-03', 'Accepted', '2026-09-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000651', 'APP-2026-00659', '2026-09-05', 750, 'Cash'),
('OR-2026-000652', 'APP-2026-00659', '2026-09-02', 150, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00468', 'APP-2026-00659', '2026-09-29', '2026-09-29', '2027-09-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00660', 'AP-00100', 'GF-00054', '2026-08-31', 'New', 'Approved', '2026-09-11', 'LC04', 'Bagong Silangan', 'ACQ-80833-26', '2026-08-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00660', 1, 'Identity', 'REF-482427', '2026-08-31', 'Accepted', '2026-09-05', NULL),
('APP-2026-00660', 2, 'Registration', 'DOC-419352', '2026-09-05', 'Accepted', '2026-09-08', NULL),
('APP-2026-00660', 3, 'Acquisition', 'ACQ-80833-26', '2026-09-04', 'Accepted', '2026-09-06', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000653', 'APP-2026-00660', '2026-09-01', 450, 'Cash'),
('OR-2026-000654', 'APP-2026-00660', '2026-09-06', 200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00469', 'APP-2026-00660', '2026-09-13', '2026-09-13', '2027-09-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00661', 'AP-00139', 'GF-00163', '2026-09-02', 'New', 'Approved', '2026-09-20', 'LC04', 'Bagong Silangan', 'ACQ-47234-26', '2026-07-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00661', 1, 'Identity', 'FILE-952385', '2026-09-02', 'Accepted', '2026-09-06', NULL),
('APP-2026-00661', 2, 'Registration', 'REF-442985', '2026-09-03', 'Accepted', '2026-09-09', NULL),
('APP-2026-00661', 3, 'Acquisition', 'ACQ-47234-26', '2026-09-04', 'Accepted', '2026-09-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000655', 'APP-2026-00661', '2026-09-11', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00470', 'APP-2026-00661', '2026-09-25', '2026-09-25', '2027-09-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00662', 'AP-00135', 'GF-00116', '2026-09-02', 'Renewal', 'Approved', '2026-09-08', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00244', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00662', 1, 'Identity', 'FILE-128528', '2026-09-02', 'Accepted', '2026-09-04', NULL),
('APP-2026-00662', 2, 'Registration', 'FILE-967018', '2026-09-05', 'Accepted', '2026-09-08', NULL),
('APP-2026-00662', 3, 'PriorPermit', 'PM-2025-00244', '2026-09-07', 'Accepted', '2026-09-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000656', 'APP-2026-00662', '2026-09-06', 450, 'Online'),
('OR-2026-000657', 'APP-2026-00662', '2026-09-03', 150, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00663', 'AP-00107', 'GF-00081', '2026-09-04', 'New', 'Approved', '2026-09-24', 'LC06', 'Maligaya', 'ACQ-84738-26', '2026-06-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00663', 1, 'Identity', 'FILE-34279', '2026-09-04', 'Accepted', '2026-09-09', NULL),
('APP-2026-00663', 2, 'Registration', 'REF-987758', '2026-09-07', 'Accepted', '2026-09-09', NULL),
('APP-2026-00663', 3, 'Acquisition', 'ACQ-84738-26', '2026-09-05', 'Accepted', '2026-09-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000658', 'APP-2026-00663', '2026-09-09', 600, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00471', 'APP-2026-00663', '2026-09-25', '2026-09-25', '2027-09-24', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00664', 'AP-00165', 'GF-00165', '2026-09-05', 'New', 'Approved', '2026-09-25', 'LC07', 'Pulo Verde', 'ACQ-33393-26', '2026-08-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00664', 1, 'Identity', 'FILE-421740', '2026-09-05', 'Accepted', '2026-09-09', NULL),
('APP-2026-00664', 2, 'Registration', 'DOC-388473', '2026-09-08', 'Accepted', '2026-09-09', NULL),
('APP-2026-00664', 3, 'Acquisition', 'ACQ-33393-26', '2026-09-09', 'Accepted', '2026-09-14', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000659', 'APP-2026-00664', '2026-09-11', 1200, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00472', 'APP-2026-00664', '2026-09-29', '2026-09-29', '2027-09-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00665', 'AP-00156', 'GF-00002', '2026-09-06', 'Renewal', 'Approved', '2026-09-19', 'LC06', 'Maligaya', NULL, NULL, 'PM-2025-00187', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00665', 1, 'Identity', 'REF-577422', '2026-09-06', 'Accepted', '2026-09-12', NULL),
('APP-2026-00665', 2, 'Registration', 'REF-797957', '2026-09-06', 'Accepted', '2026-09-09', NULL),
('APP-2026-00665', 3, 'PriorPermit', 'PM-2025-00187', '2026-09-07', 'Accepted', '2026-09-08', NULL),
('APP-2026-00665', 4, 'Other', 'FILE-596415', '2026-09-09', 'Accepted', '2026-09-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000660', 'APP-2026-00665', '2026-09-10', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00666', 'AP-00150', 'GF-00048', '2026-09-07', 'New', 'Submitted', NULL, 'LC05', 'Santa Elena', 'ACQ-32793-26', '2026-07-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00666', 1, 'Identity', 'REF-840464', '2026-09-07', 'Pending', NULL, NULL),
('APP-2026-00666', 2, 'Registration', 'REF-798794', '2026-09-11', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000661', 'APP-2026-00666', '2026-09-15', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00667', 'AP-00184', 'GF-00012', '2026-09-07', 'New', 'Submitted', NULL, 'LC04', 'Bagong Silangan', 'ACQ-54901-26', '2026-07-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00667', 1, 'Identity', 'REF-135155', '2026-09-07', 'Pending', NULL, NULL),
('APP-2026-00667', 2, 'Registration', 'FILE-244200', '2026-09-10', 'Pending', NULL, NULL),
('APP-2026-00667', 3, 'Acquisition', 'ACQ-54901-26', '2026-09-12', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000662', 'APP-2026-00667', '2026-09-15', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00668', 'AP-00133', 'GF-00067', '2026-09-10', 'New', 'Rejected', '2026-09-27', 'LC08', 'San Rafael Norte', 'ACQ-36579-26', '2026-08-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00668', 1, 'Identity', 'DOC-71149', '2026-09-10', 'NeedsCorrection', '2026-09-13', 'The submitted name requires clarification against the application.'),
('APP-2026-00668', 2, 'Registration', 'DOC-49033', '2026-09-10', 'NeedsCorrection', '2026-09-13', 'The date on the document needs clarification.'),
('APP-2026-00668', 3, 'Acquisition', 'ACQ-36579-26', '2026-09-14', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000663', 'APP-2026-00668', '2026-09-11', 600, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00669', 'AP-00036', 'GF-00044', '2026-09-11', 'New', 'Rejected', '2026-10-06', 'LC01', 'Luntian Central', 'ACQ-10897-26', '2026-06-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00669', 1, 'Identity', 'REF-499675', '2026-09-11', 'NeedsCorrection', '2026-09-13', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00669', 2, 'Registration', 'REF-239449', '2026-09-15', 'Accepted', '2026-09-17', NULL),
('APP-2026-00669', 3, 'Acquisition', 'ACQ-10897-26', '2026-09-11', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000664', 'APP-2026-00669', '2026-09-20', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00670', 'AP-00059', 'GF-00144', '2026-09-11', 'New', 'Approved', '2026-10-07', 'LC05', 'Santa Elena', 'ACQ-10900-26', '2026-06-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00670', 1, 'Identity', 'REF-511817', '2026-09-11', 'Accepted', '2026-09-18', NULL),
('APP-2026-00670', 2, 'Registration', 'REF-775875', '2026-09-11', 'Accepted', '2026-09-16', NULL),
('APP-2026-00670', 3, 'Acquisition', 'ACQ-10900-26', '2026-09-16', 'Accepted', '2026-09-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000665', 'APP-2026-00670', '2026-09-21', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00473', 'APP-2026-00670', '2026-10-07', '2026-10-07', '2027-10-06', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00671', 'AP-00119', 'GF-00065', '2026-09-11', 'New', 'Approved', '2026-09-18', 'LC01', 'Luntian Central', 'ACQ-19112-26', '2026-05-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00671', 1, 'Identity', 'REF-937146', '2026-09-11', 'Accepted', '2026-09-18', NULL),
('APP-2026-00671', 2, 'Registration', 'FILE-11943', '2026-09-14', 'Accepted', '2026-09-18', NULL),
('APP-2026-00671', 3, 'Acquisition', 'ACQ-19112-26', '2026-09-11', 'Accepted', '2026-09-12', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000666', 'APP-2026-00671', '2026-09-18', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00474', 'APP-2026-00671', '2026-09-19', '2026-09-19', '2027-09-18', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00672', 'AP-00052', 'GF-00122', '2026-09-11', 'New', 'Submitted', NULL, 'LC01', 'Luntian Central', 'ACQ-56922-26', '2026-08-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00672', 1, 'Identity', 'FILE-716895', '2026-09-11', 'Pending', NULL, NULL),
('APP-2026-00672', 2, 'Registration', 'DOC-71235', '2026-09-12', 'Pending', NULL, NULL),
('APP-2026-00672', 3, 'Acquisition', 'ACQ-56922-26', '2026-09-14', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000667', 'APP-2026-00672', '2026-09-22', 900, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00673', 'AP-00031', 'GF-00131', '2026-09-12', 'Replacement', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', NULL, NULL, NULL, NULL, '2026-08-25', 'IR-2026-2082');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00673', 1, 'Identity', 'FILE-248874', '2026-09-12', 'Pending', NULL, NULL),
('APP-2026-00673', 2, 'Registration', 'FILE-178189', '2026-09-16', 'Accepted', '2026-09-20', NULL),
('APP-2026-00673', 3, 'Incident', 'IR-2026-2082', '2026-09-15', 'NeedsCorrection', '2026-09-16', 'Please provide the missing page of the supporting document.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00674', 'AP-00146', 'GF-00068', '2026-09-13', 'New', 'Approved', '2026-09-26', 'LC07', 'Pulo Verde', 'ACQ-51305-26', '2026-07-15', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00674', 1, 'Identity', 'REF-464173', '2026-09-13', 'Accepted', '2026-09-20', NULL),
('APP-2026-00674', 2, 'Registration', 'FILE-276016', '2026-09-16', 'Accepted', '2026-09-17', NULL),
('APP-2026-00674', 3, 'Acquisition', 'ACQ-51305-26', '2026-09-13', 'Accepted', '2026-09-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000668', 'APP-2026-00674', '2026-09-16', 900, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00475', 'APP-2026-00674', '2026-09-30', '2026-09-30', '2027-09-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00675', 'AP-00095', 'GF-00036', '2026-09-13', 'New', 'Approved', '2026-09-16', 'LC03', 'Mabini East', 'ACQ-35643-26', '2026-06-23', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00675', 1, 'Identity', 'REF-992715', '2026-09-13', 'Accepted', '2026-09-16', NULL),
('APP-2026-00675', 2, 'Registration', 'REF-803297', '2026-09-14', 'Accepted', '2026-09-16', NULL),
('APP-2026-00675', 3, 'Acquisition', 'ACQ-35643-26', '2026-09-14', 'Accepted', '2026-09-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000669', 'APP-2026-00675', '2026-09-13', 1200, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00476', 'APP-2026-00675', '2026-09-21', '2026-09-21', '2027-09-20', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00676', 'AP-00046', 'GF-00007', '2026-09-13', 'Renewal', 'UnderReview', NULL, 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2025-00081', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00676', 1, 'Identity', 'DOC-372969', '2026-09-13', 'Accepted', '2026-09-16', NULL),
('APP-2026-00676', 2, 'Registration', 'DOC-261384', '2026-09-16', 'Pending', NULL, NULL),
('APP-2026-00676', 3, 'PriorPermit', 'PM-2025-00081', '2026-09-13', 'Accepted', '2026-09-20', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00677', 'AP-00034', 'GF-00126', '2026-09-14', 'New', 'UnderReview', NULL, 'LC07', 'Pulo Verde', 'ACQ-72122-26', '2026-08-31', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00677', 1, 'Identity', 'FILE-967006', '2026-09-14', 'NeedsCorrection', '2026-09-18', 'Please provide the missing page of the supporting document.'),
('APP-2026-00677', 2, 'Registration', 'DOC-184181', '2026-09-15', 'NeedsCorrection', '2026-09-21', 'The submitted name requires clarification against the application.'),
('APP-2026-00677', 3, 'Acquisition', 'ACQ-72122-26', '2026-09-19', 'Accepted', '2026-09-22', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000670', 'APP-2026-00677', '2026-09-21', 900, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00678', 'AP-00049', 'GF-00146', '2026-09-14', 'New', 'Approved', '2026-09-30', 'LC04', 'Bagong Silangan', 'ACQ-53227-26', '2026-08-16', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00678', 1, 'Identity', 'DOC-573346', '2026-09-14', 'Accepted', '2026-09-15', NULL),
('APP-2026-00678', 2, 'Registration', 'REF-97910', '2026-09-19', 'Accepted', '2026-09-23', NULL),
('APP-2026-00678', 3, 'Acquisition', 'ACQ-53227-26', '2026-09-17', 'Accepted', '2026-09-18', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000671', 'APP-2026-00678', '2026-09-19', 900, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00477', 'APP-2026-00678', '2026-10-05', '2026-10-05', '2027-10-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00679', 'AP-00181', 'GF-00071', '2026-09-14', 'Replacement', 'Approved', '2026-10-08', 'LC07', 'Pulo Verde', NULL, NULL, NULL, NULL, '2026-08-18', 'IR-2026-4071');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00679', 1, 'Identity', 'DOC-199321', '2026-09-14', 'Accepted', '2026-09-18', NULL),
('APP-2026-00679', 2, 'Registration', 'DOC-213049', '2026-09-18', 'Accepted', '2026-09-23', NULL),
('APP-2026-00679', 3, 'Incident', 'IR-2026-4071', '2026-09-15', 'Accepted', '2026-09-16', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000672', 'APP-2026-00679', '2026-09-24', 600, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00478', 'APP-2026-00679', '2026-10-13', '2026-10-13', '2027-10-12', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00680', 'AP-00150', 'GF-00153', '2026-09-16', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-98883-26', '2026-09-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00680', 1, 'Identity', 'REF-973590', '2026-09-16', 'Accepted', '2026-09-19', NULL),
('APP-2026-00680', 2, 'Registration', 'FILE-427953', '2026-09-19', 'Pending', NULL, NULL),
('APP-2026-00680', 3, 'Acquisition', 'ACQ-98883-26', '2026-09-17', 'Pending', NULL, NULL),
('APP-2026-00680', 4, 'Other', 'REF-972325', '2026-09-17', 'NeedsCorrection', '2026-09-24', 'The submitted name requires clarification against the application.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000673', 'APP-2026-00680', '2026-09-19', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00681', 'AP-00115', 'GF-00089', '2026-09-16', 'Renewal', 'Approved', '2026-09-25', 'LC06', 'Maligaya', NULL, NULL, 'PM-2026-00287', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00681', 1, 'Identity', 'REF-326467', '2026-09-16', 'Accepted', '2026-09-22', NULL),
('APP-2026-00681', 2, 'Registration', 'REF-834138', '2026-09-18', 'Accepted', '2026-09-20', NULL),
('APP-2026-00681', 3, 'PriorPermit', 'PM-2026-00287', '2026-09-19', 'Accepted', '2026-09-20', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000674', 'APP-2026-00681', '2026-09-18', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00479', 'APP-2026-00681', '2026-09-29', '2026-09-29', '2027-09-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00682', 'AP-00180', 'GF-00140', '2026-09-17', 'New', 'Approved', '2026-09-25', 'LC07', 'Pulo Verde', 'ACQ-54006-26', '2026-07-17', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00682', 1, 'Identity', 'DOC-209761', '2026-09-17', 'Accepted', '2026-09-20', NULL),
('APP-2026-00682', 2, 'Registration', 'DOC-203298', '2026-09-20', 'Accepted', '2026-09-25', NULL),
('APP-2026-00682', 3, 'Acquisition', 'ACQ-54006-26', '2026-09-22', 'Accepted', '2026-09-24', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000675', 'APP-2026-00682', '2026-09-22', 1200, 'Online'),
('OR-2026-000676', 'APP-2026-00682', '2026-09-20', 100, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00480', 'APP-2026-00682', '2026-09-29', '2026-09-29', '2027-09-28', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00683', 'AP-00117', 'GF-00062', '2026-09-20', 'New', 'Approved', '2026-10-07', 'LC04', 'Bagong Silangan', 'ACQ-88239-26', '2026-06-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00683', 1, 'Identity', 'DOC-896598', '2026-09-20', 'Accepted', '2026-09-21', NULL),
('APP-2026-00683', 2, 'Registration', 'FILE-796084', '2026-09-20', 'Accepted', '2026-09-26', NULL),
('APP-2026-00683', 3, 'Acquisition', 'ACQ-88239-26', '2026-09-22', 'Accepted', '2026-09-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000677', 'APP-2026-00683', '2026-09-21', 600, 'BankTransfer'),
('OR-2026-000678', 'APP-2026-00683', '2026-09-21', 100, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00481', 'APP-2026-00683', '2026-10-11', '2026-10-11', '2027-10-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00684', 'AP-00173', 'GF-00118', '2026-09-21', 'New', 'Submitted', NULL, 'LC01', 'Luntian Central', 'ACQ-32530-26', '2026-07-27', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00684', 1, 'Identity', 'REF-982639', '2026-09-21', 'Pending', NULL, NULL),
('APP-2026-00684', 2, 'Registration', 'REF-705130', '2026-09-23', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000679', 'APP-2026-00684', '2026-10-02', 350, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00685', 'AP-00151', 'GF-00053', '2026-09-22', 'New', 'Approved', '2026-10-02', 'LC06', 'Maligaya', 'ACQ-32662-26', '2026-09-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00685', 1, 'Identity', 'DOC-928659', '2026-09-22', 'Accepted', '2026-09-25', NULL),
('APP-2026-00685', 2, 'Registration', 'DOC-148824', '2026-09-22', 'Accepted', '2026-09-27', NULL),
('APP-2026-00685', 3, 'Acquisition', 'ACQ-32662-26', '2026-09-24', 'Accepted', '2026-10-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000680', 'APP-2026-00685', '2026-09-23', 750, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00482', 'APP-2026-00685', '2026-10-05', '2026-10-05', '2027-10-04', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00686', 'AP-00095', 'GF-00090', '2026-09-25', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-94657-26', '2026-08-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00686', 1, 'Identity', 'DOC-648407', '2026-09-25', 'Accepted', '2026-09-29', NULL),
('APP-2026-00686', 2, 'Registration', 'REF-768351', '2026-09-28', 'Accepted', '2026-10-03', NULL),
('APP-2026-00686', 3, 'Acquisition', 'ACQ-94657-26', '2026-09-25', 'Accepted', '2026-09-27', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00687', 'AP-00034', 'GF-00078', '2026-09-26', 'New', 'Approved', '2026-10-10', 'LC04', 'Bagong Silangan', 'ACQ-89837-26', '2026-06-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00687', 1, 'Identity', 'DOC-786055', '2026-09-26', 'Accepted', '2026-09-30', NULL),
('APP-2026-00687', 2, 'Registration', 'FILE-63786', '2026-09-27', 'Accepted', '2026-10-02', NULL),
('APP-2026-00687', 3, 'Acquisition', 'ACQ-89837-26', '2026-09-26', 'Accepted', '2026-10-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000681', 'APP-2026-00687', '2026-10-03', 1200, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00483', 'APP-2026-00687', '2026-10-11', '2026-10-11', '2027-10-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00688', 'AP-00006', 'GF-00036', '2026-09-26', 'Replacement', 'UnderReview', NULL, 'LC03', 'Mabini East', NULL, NULL, NULL, NULL, '2026-09-03', 'IR-2026-8542');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00688', 1, 'Identity', 'FILE-746540', '2026-09-26', 'Accepted', '2026-10-01', NULL),
('APP-2026-00688', 2, 'Registration', 'DOC-919965', '2026-09-28', 'Accepted', '2026-10-04', NULL),
('APP-2026-00688', 3, 'Incident', 'IR-2026-8542', '2026-09-30', 'Accepted', '2026-10-01', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000682', 'APP-2026-00688', '2026-10-07', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00689', 'AP-00038', 'GF-00156', '2026-09-27', 'New', 'Approved', '2026-11-03', 'LC03', 'Mabini East', 'ACQ-84504-26', '2026-07-07', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00689', 1, 'Identity', 'FILE-365671', '2026-09-27', 'Accepted', '2026-09-29', NULL),
('APP-2026-00689', 2, 'Registration', 'FILE-519642', '2026-10-01', 'Accepted', '2026-10-04', NULL),
('APP-2026-00689', 3, 'Acquisition', 'ACQ-84504-26', '2026-10-01', 'Accepted', '2026-10-05', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000683', 'APP-2026-00689', '2026-10-06', 450, 'Cash'),
('OR-2026-000684', 'APP-2026-00689', '2026-09-27', 150, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00690', 'AP-00047', 'GF-00055', '2026-09-27', 'New', 'Submitted', NULL, 'LC02', 'San Isidro Heights', 'ACQ-63395-26', '2026-07-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00690', 1, 'Identity', 'REF-810186', '2026-09-27', 'Pending', NULL, NULL),
('APP-2026-00690', 2, 'Registration', 'FILE-404124', '2026-09-27', 'Pending', NULL, NULL),
('APP-2026-00690', 3, 'Acquisition', 'ACQ-63395-26', '2026-09-28', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00691', 'AP-00116', 'GF-00124', '2026-09-27', 'Renewal', 'Approved', '2026-09-30', 'LC04', 'Bagong Silangan', NULL, NULL, 'PM-2025-00151', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00691', 1, 'Identity', 'DOC-823214', '2026-09-27', 'Accepted', '2026-09-30', NULL),
('APP-2026-00691', 2, 'Registration', 'DOC-546668', '2026-09-30', 'Accepted', '2026-09-30', NULL),
('APP-2026-00691', 3, 'PriorPermit', 'PM-2025-00151', '2026-09-30', 'Accepted', '2026-09-30', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000685', 'APP-2026-00691', '2026-09-30', 750, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00484', 'APP-2026-00691', '2026-09-30', '2026-09-30', '2027-09-29', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00692', 'AP-00176', 'GF-00071', '2026-09-28', 'New', 'Withdrawn', NULL, 'LC04', 'Bagong Silangan', 'ACQ-89931-26', '2026-08-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00692', 1, 'Identity', 'DOC-852232', '2026-09-28', 'Accepted', '2026-09-30', NULL),
('APP-2026-00692', 2, 'Registration', 'FILE-969594', '2026-09-28', 'Accepted', '2026-10-03', NULL),
('APP-2026-00692', 3, 'Acquisition', 'ACQ-89931-26', '2026-10-03', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00693', 'AP-00032', 'GF-00087', '2026-09-29', 'New', 'UnderReview', NULL, 'LC06', 'Maligaya', 'ACQ-54083-26', '2026-08-25', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00693', 1, 'Identity', 'DOC-482826', '2026-09-29', 'Accepted', '2026-09-30', NULL),
('APP-2026-00693', 2, 'Registration', 'DOC-804133', '2026-09-29', 'Pending', NULL, NULL),
('APP-2026-00693', 3, 'Acquisition', 'ACQ-54083-26', '2026-10-04', 'Accepted', '2026-10-10', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00694', 'AP-00172', 'GF-00154', '2026-09-29', 'Replacement', 'UnderReview', NULL, 'LC06', 'Maligaya', NULL, NULL, NULL, NULL, '2026-09-15', 'IR-2026-1534');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00694', 1, 'Identity', 'REF-832877', '2026-09-29', 'Pending', NULL, NULL),
('APP-2026-00694', 2, 'Registration', 'FILE-948472', '2026-10-03', 'Pending', NULL, NULL),
('APP-2026-00694', 3, 'Incident', 'IR-2026-1534', '2026-09-30', 'Accepted', '2026-10-02', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000686', 'APP-2026-00694', '2026-10-02', 450, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00695', 'AP-00161', 'GF-00021', '2026-10-01', 'Renewal', 'UnderReview', NULL, 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00265', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00695', 1, 'Identity', 'FILE-586767', '2026-10-01', 'Accepted', '2026-10-07', NULL),
('APP-2026-00695', 2, 'Registration', 'DOC-321768', '2026-10-02', 'Accepted', '2026-10-06', NULL),
('APP-2026-00695', 3, 'PriorPermit', 'PM-2025-00265', '2026-10-01', 'Accepted', '2026-10-03', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00696', 'AP-00123', 'GF-00078', '2026-10-01', 'Renewal', 'Approved', '2026-10-18', 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00065', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00696', 1, 'Identity', 'DOC-748250', '2026-10-01', 'Accepted', '2026-10-05', NULL),
('APP-2026-00696', 2, 'Registration', 'DOC-501187', '2026-10-05', 'Accepted', '2026-10-08', NULL),
('APP-2026-00696', 3, 'PriorPermit', 'PM-2025-00065', '2026-10-02', 'Accepted', '2026-10-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000687', 'APP-2026-00696', '2026-10-12', 900, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00697', 'AP-00052', 'GF-00164', '2026-10-02', 'New', 'Submitted', NULL, 'LC01', 'Luntian Central', 'ACQ-89950-26', '2026-09-14', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00697', 1, 'Identity', 'FILE-218888', '2026-10-02', 'Pending', NULL, NULL),
('APP-2026-00697', 2, 'Registration', 'FILE-983067', '2026-10-02', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00698', 'AP-00045', 'GF-00041', '2026-10-03', 'New', 'UnderReview', NULL, 'LC06', 'Maligaya', 'ACQ-95172-26', '2026-06-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00698', 1, 'Identity', 'REF-896140', '2026-10-03', 'Accepted', '2026-10-04', NULL),
('APP-2026-00698', 2, 'Registration', 'FILE-90190', '2026-10-04', 'Accepted', '2026-10-05', NULL),
('APP-2026-00698', 3, 'Acquisition', 'ACQ-95172-26', '2026-10-04', 'Pending', NULL, NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00699', 'AP-00081', 'GF-00117', '2026-10-03', 'New', 'Approved', '2026-10-24', 'LC02', 'San Isidro Heights', 'ACQ-56700-26', '2026-09-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00699', 1, 'Identity', 'DOC-531373', '2026-10-03', 'Accepted', '2026-10-07', NULL),
('APP-2026-00699', 2, 'Registration', 'DOC-953713', '2026-10-05', 'Accepted', '2026-10-12', NULL),
('APP-2026-00699', 3, 'Acquisition', 'ACQ-56700-26', '2026-10-08', 'Accepted', '2026-10-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000688', 'APP-2026-00699', '2026-10-04', 900, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00700', 'AP-00153', 'GF-00002', '2026-10-03', 'New', 'Approved', '2026-10-07', 'LC04', 'Bagong Silangan', 'ACQ-55274-26', '2026-09-09', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00700', 1, 'Identity', 'DOC-508493', '2026-10-03', 'Accepted', '2026-10-07', NULL),
('APP-2026-00700', 2, 'Registration', 'REF-736108', '2026-10-03', 'Accepted', '2026-10-07', NULL),
('APP-2026-00700', 3, 'Acquisition', 'ACQ-55274-26', '2026-10-07', 'Accepted', '2026-10-07', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000689', 'APP-2026-00700', '2026-10-06', 450, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00485', 'APP-2026-00700', '2026-10-11', '2026-10-11', '2027-10-10', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00701', 'AP-00132', 'GF-00063', '2026-10-05', 'New', 'Approved', '2026-10-27', 'LC02', 'San Isidro Heights', 'ACQ-65397-26', '2026-06-29', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00701', 1, 'Identity', 'FILE-731177', '2026-10-05', 'Accepted', '2026-10-12', NULL),
('APP-2026-00701', 2, 'Registration', 'REF-182093', '2026-10-05', 'Accepted', '2026-10-11', NULL),
('APP-2026-00701', 3, 'Acquisition', 'ACQ-65397-26', '2026-10-09', 'Accepted', '2026-10-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000690', 'APP-2026-00701', '2026-10-08', 750, 'Cash');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00486', 'APP-2026-00701', '2026-10-27', '2026-10-27', '2027-10-26', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00702', 'AP-00163', 'GF-00143', '2026-10-05', 'Replacement', 'Withdrawn', NULL, 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2026-09-30', 'IR-2026-5575');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00702', 1, 'Identity', 'DOC-596312', '2026-10-05', 'Pending', NULL, NULL),
('APP-2026-00702', 2, 'Registration', 'DOC-78693', '2026-10-10', 'Pending', NULL, NULL),
('APP-2026-00702', 3, 'Incident', 'IR-2026-5575', '2026-10-10', 'NeedsCorrection', '2026-10-13', 'The recorded reference must be verified with the submitted copy.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00703', 'AP-00050', 'GF-00099', '2026-10-06', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-29162-26', '2026-08-13', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00703', 1, 'Identity', 'DOC-221892', '2026-10-06', 'Accepted', '2026-10-09', NULL),
('APP-2026-00703', 2, 'Registration', 'REF-65202', '2026-10-10', 'NeedsCorrection', '2026-10-11', 'The submitted name requires clarification against the application.'),
('APP-2026-00703', 3, 'Acquisition', 'ACQ-29162-26', '2026-10-07', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000691', 'APP-2026-00703', '2026-10-15', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00704', 'AP-00166', 'GF-00016', '2026-10-06', 'Replacement', 'UnderReview', NULL, 'LC05', 'Santa Elena', NULL, NULL, NULL, NULL, '2026-09-29', 'IR-2026-1334');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00704', 1, 'Identity', 'FILE-817650', '2026-10-06', 'NeedsCorrection', '2026-10-11', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00704', 2, 'Registration', 'DOC-560256', '2026-10-11', 'Accepted', '2026-10-14', NULL),
('APP-2026-00704', 3, 'Incident', 'IR-2026-1334', '2026-10-11', 'NeedsCorrection', '2026-10-15', 'Please provide the missing page of the supporting document.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000692', 'APP-2026-00704', '2026-10-18', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00705', 'AP-00142', 'GF-00040', '2026-10-07', 'New', 'UnderReview', NULL, 'LC07', 'Pulo Verde', 'ACQ-68560-26', '2026-08-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00705', 1, 'Identity', 'FILE-763862', '2026-10-07', 'NeedsCorrection', '2026-10-11', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00705', 2, 'Registration', 'DOC-886037', '2026-10-11', 'Accepted', '2026-10-17', NULL),
('APP-2026-00705', 3, 'Acquisition', 'ACQ-68560-26', '2026-10-08', 'NeedsCorrection', '2026-10-09', 'Please provide the missing page of the supporting document.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000693', 'APP-2026-00705', '2026-10-18', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00706', 'AP-00162', 'GF-00045', '2026-10-07', 'New', 'Approved', '2026-10-31', 'LC01', 'Luntian Central', 'ACQ-25290-26', '2026-08-20', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00706', 1, 'Identity', 'REF-622830', '2026-10-07', 'Accepted', '2026-10-11', NULL),
('APP-2026-00706', 2, 'Registration', 'FILE-594627', '2026-10-10', 'Accepted', '2026-10-17', NULL),
('APP-2026-00706', 3, 'Acquisition', 'ACQ-25290-26', '2026-10-12', 'Accepted', '2026-10-18', NULL),
('APP-2026-00706', 4, 'Other', 'REF-632426', '2026-10-07', 'Accepted', '2026-10-08', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000694', 'APP-2026-00706', '2026-10-10', 600, 'Online'),
('OR-2026-000695', 'APP-2026-00706', '2026-10-16', 150, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00707', 'AP-00098', 'GF-00053', '2026-10-07', 'New', 'Withdrawn', NULL, 'LC02', 'San Isidro Heights', 'ACQ-63019-26', '2026-09-24', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00707', 1, 'Identity', 'REF-142947', '2026-10-07', 'Pending', NULL, NULL),
('APP-2026-00707', 2, 'Registration', 'REF-848106', '2026-10-08', 'Accepted', '2026-10-14', NULL),
('APP-2026-00707', 3, 'Acquisition', 'ACQ-63019-26', '2026-10-07', 'Accepted', '2026-10-12', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00708', 'AP-00161', 'GF-00147', '2026-10-07', 'Replacement', 'UnderReview', NULL, 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2026-09-11', 'IR-2026-4396');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00708', 1, 'Identity', 'REF-499976', '2026-10-07', 'Pending', NULL, NULL),
('APP-2026-00708', 2, 'Registration', 'DOC-589829', '2026-10-12', 'Pending', NULL, NULL),
('APP-2026-00708', 3, 'Incident', 'IR-2026-4396', '2026-10-12', 'Pending', NULL, NULL),
('APP-2026-00708', 4, 'Other', 'DOC-418549', '2026-10-07', 'Accepted', '2026-10-10', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000696', 'APP-2026-00708', '2026-10-14', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00709', 'AP-00051', 'GF-00054', '2026-10-08', 'New', 'Approved', '2026-11-01', 'LC02', 'San Isidro Heights', 'ACQ-79975-26', '2026-06-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00709', 1, 'Identity', 'REF-229372', '2026-10-08', 'Accepted', '2026-10-12', NULL),
('APP-2026-00709', 2, 'Registration', 'DOC-611743', '2026-10-09', 'Accepted', '2026-10-16', NULL),
('APP-2026-00709', 3, 'Acquisition', 'ACQ-79975-26', '2026-10-12', 'Accepted', '2026-10-13', NULL),
('APP-2026-00709', 4, 'Other', 'FILE-157488', '2026-10-10', 'Accepted', '2026-10-11', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000697', 'APP-2026-00709', '2026-10-10', 450, 'Online');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00487', 'APP-2026-00709', '2026-11-03', '2026-11-03', '2027-11-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00710', 'AP-00016', 'GF-00057', '2026-10-10', 'Renewal', 'Rejected', '2026-10-27', 'LC06', 'Maligaya', NULL, NULL, 'PM-2025-00068', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00710', 1, 'Identity', 'FILE-208076', '2026-10-10', 'Pending', NULL, NULL),
('APP-2026-00710', 2, 'Registration', 'FILE-724823', '2026-10-10', 'NeedsCorrection', '2026-10-13', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00710', 3, 'PriorPermit', 'PM-2025-00068', '2026-10-14', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000698', 'APP-2026-00710', '2026-10-21', 750, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00711', 'AP-00051', 'GF-00058', '2026-10-13', 'New', 'UnderReview', NULL, 'LC02', 'San Isidro Heights', 'ACQ-52990-26', '2026-06-30', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00711', 1, 'Identity', 'DOC-984700', '2026-10-13', 'Pending', NULL, NULL),
('APP-2026-00711', 2, 'Registration', 'DOC-397147', '2026-10-16', 'Accepted', '2026-10-18', NULL),
('APP-2026-00711', 3, 'Acquisition', 'ACQ-52990-26', '2026-10-13', 'Accepted', '2026-10-15', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00712', 'AP-00115', 'GF-00089', '2026-10-14', 'Renewal', 'Rejected', '2026-10-19', 'LC02', 'San Isidro Heights', NULL, NULL, 'PM-2026-00287', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00712', 1, 'Identity', 'FILE-130053', '2026-10-14', 'Accepted', '2026-10-19', NULL),
('APP-2026-00712', 2, 'Registration', 'DOC-64000', '2026-10-15', 'Pending', NULL, NULL),
('APP-2026-00712', 3, 'PriorPermit', 'PM-2026-00287', '2026-10-17', 'NeedsCorrection', '2026-10-19', 'A clearer copy of the reference portion is requested.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00713', 'AP-00057', 'GF-00022', '2026-10-14', 'Renewal', 'UnderReview', NULL, 'LC03', 'Mabini East', NULL, NULL, 'PM-2025-00045', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00713', 1, 'Identity', 'DOC-374777', '2026-10-14', 'Pending', NULL, NULL),
('APP-2026-00713', 2, 'Registration', 'DOC-800187', '2026-10-16', 'NeedsCorrection', '2026-10-17', 'The submitted name requires clarification against the application.'),
('APP-2026-00713', 3, 'PriorPermit', 'PM-2025-00045', '2026-10-18', 'Accepted', '2026-10-20', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00714', 'AP-00066', 'GF-00109', '2026-10-15', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-92149-26', '2026-07-02', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00714', 1, 'Identity', 'REF-376227', '2026-10-15', 'Pending', NULL, NULL),
('APP-2026-00714', 2, 'Registration', 'DOC-613042', '2026-10-16', 'Accepted', '2026-10-23', NULL),
('APP-2026-00714', 3, 'Acquisition', 'ACQ-92149-26', '2026-10-16', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000699', 'APP-2026-00714', '2026-10-24', 350, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00715', 'AP-00007', 'GF-00094', '2026-10-16', 'New', 'UnderReview', NULL, 'LC06', 'Maligaya', 'ACQ-57859-26', '2026-09-06', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00715', 1, 'Identity', 'DOC-285693', '2026-10-16', 'Pending', NULL, NULL),
('APP-2026-00715', 2, 'Registration', 'FILE-349991', '2026-10-21', 'Accepted', '2026-10-24', NULL),
('APP-2026-00715', 3, 'Acquisition', 'ACQ-57859-26', '2026-10-19', 'Pending', NULL, NULL),
('APP-2026-00715', 4, 'Other', 'FILE-723776', '2026-10-19', 'NeedsCorrection', '2026-10-25', 'Please provide the missing page of the supporting document.');



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00716', 'AP-00128', 'GF-00100', '2026-10-17', 'Replacement', 'Withdrawn', NULL, 'LC01', 'Luntian Central', NULL, NULL, NULL, NULL, '2026-09-22', 'IR-2026-4604');

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00716', 1, 'Identity', 'REF-84256', '2026-10-17', 'Accepted', '2026-10-18', NULL),
('APP-2026-00716', 2, 'Registration', 'REF-71582', '2026-10-22', 'Pending', NULL, NULL),
('APP-2026-00716', 3, 'Incident', 'IR-2026-4604', '2026-10-21', 'Accepted', '2026-10-23', NULL);



INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00717', 'AP-00086', 'GF-00127', '2026-10-20', 'New', 'UnderReview', NULL, 'LC02', 'San Isidro Heights', 'ACQ-21043-26', '2026-09-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00717', 1, 'Identity', 'REF-976887', '2026-10-20', 'Accepted', '2026-10-23', NULL),
('APP-2026-00717', 2, 'Registration', 'REF-95395', '2026-10-21', 'Accepted', '2026-10-26', NULL),
('APP-2026-00717', 3, 'Acquisition', 'ACQ-21043-26', '2026-10-23', 'Accepted', '2026-10-27', NULL),
('APP-2026-00717', 4, 'Other', 'FILE-864194', '2026-10-24', 'Accepted', '2026-10-29', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000700', 'APP-2026-00717', '2026-10-29', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00718', 'AP-00062', 'GF-00142', '2026-10-21', 'New', 'Submitted', NULL, 'LC02', 'San Isidro Heights', 'ACQ-98672-26', '2026-06-26', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00718', 1, 'Identity', 'FILE-34494', '2026-10-21', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000701', 'APP-2026-00718', '2026-10-23', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00719', 'AP-00090', 'GF-00089', '2026-10-21', 'Renewal', 'Approved', '2026-11-02', 'LC05', 'Santa Elena', NULL, NULL, 'PM-2025-00206', 'Renewal requested after reviewing the previous authorization.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00719', 1, 'Identity', 'FILE-391650', '2026-10-21', 'Accepted', '2026-10-25', NULL),
('APP-2026-00719', 2, 'Registration', 'DOC-124472', '2026-10-23', 'Accepted', '2026-10-30', NULL),
('APP-2026-00719', 3, 'PriorPermit', 'PM-2025-00206', '2026-10-24', 'Accepted', '2026-10-26', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000702', 'APP-2026-00719', '2026-10-26', 350, 'BankTransfer');

INSERT INTO permits (perm_no, app_no, issuedt, validfr, validto, permstat) VALUES
('PM-2026-00488', 'APP-2026-00719', '2026-11-03', '2026-11-03', '2027-11-02', 'Issued');

INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00720', 'AP-00179', 'GF-00083', '2026-10-24', 'New', 'Submitted', NULL, 'LC02', 'San Isidro Heights', 'ACQ-42098-26', '2026-08-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00720', 1, 'Identity', 'DOC-937882', '2026-10-24', 'Pending', NULL, NULL),
('APP-2026-00720', 2, 'Registration', 'DOC-221871', '2026-10-24', 'Pending', NULL, NULL),
('APP-2026-00720', 3, 'Acquisition', 'ACQ-42098-26', '2026-10-24', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000703', 'APP-2026-00720', '2026-11-03', 900, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00721', 'AP-00170', 'GF-00088', '2026-10-24', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-24331-26', '2026-07-28', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00721', 1, 'Identity', 'DOC-201013', '2026-10-24', 'Accepted', '2026-10-25', NULL),
('APP-2026-00721', 2, 'Registration', 'DOC-232837', '2026-10-27', 'Pending', NULL, NULL),
('APP-2026-00721', 3, 'Acquisition', 'ACQ-24331-26', '2026-10-27', 'NeedsCorrection', '2026-11-03', 'The date on the document needs clarification.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000704', 'APP-2026-00721', '2026-10-30', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00722', 'AP-00125', 'GF-00036', '2026-10-26', 'New', 'UnderReview', NULL, 'LC04', 'Bagong Silangan', 'ACQ-46986-26', '2026-10-21', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00722', 1, 'Identity', 'REF-503656', '2026-10-26', 'Accepted', '2026-11-02', NULL),
('APP-2026-00722', 2, 'Registration', 'REF-246533', '2026-10-26', 'Pending', NULL, NULL),
('APP-2026-00722', 3, 'Acquisition', 'ACQ-46986-26', '2026-10-31', 'NeedsCorrection', '2026-11-03', 'Please provide the missing page of the supporting document.'),
('APP-2026-00722', 4, 'Other', 'DOC-833803', '2026-10-27', 'Accepted', '2026-10-31', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000705', 'APP-2026-00722', '2026-11-03', 450, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00723', 'AP-00022', 'GF-00086', '2026-10-26', 'New', 'UnderReview', NULL, 'LC05', 'Santa Elena', 'ACQ-28663-26', '2026-07-01', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00723', 1, 'Identity', 'FILE-952281', '2026-10-26', 'NeedsCorrection', '2026-10-31', 'A clearer copy of the reference portion is requested.'),
('APP-2026-00723', 2, 'Registration', 'FILE-938307', '2026-10-29', 'NeedsCorrection', '2026-11-02', 'The date on the document needs clarification.'),
('APP-2026-00723', 3, 'Acquisition', 'ACQ-28663-26', '2026-10-27', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000706', 'APP-2026-00723', '2026-11-03', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00724', 'AP-00144', 'GF-00153', '2026-10-27', 'New', 'UnderReview', NULL, 'LC02', 'San Isidro Heights', 'ACQ-50049-26', '2026-09-19', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00724', 1, 'Identity', 'DOC-741765', '2026-10-27', 'Accepted', '2026-10-28', NULL),
('APP-2026-00724', 2, 'Registration', 'DOC-239768', '2026-10-28', 'Accepted', '2026-11-03', NULL),
('APP-2026-00724', 3, 'Acquisition', 'ACQ-50049-26', '2026-10-30', 'NeedsCorrection', '2026-11-03', 'The submitted name requires clarification against the application.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000707', 'APP-2026-00724', '2026-11-02', 350, 'BankTransfer');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00725', 'AP-00028', 'GF-00048', '2026-10-27', 'Renewal', 'UnderReview', NULL, 'LC01', 'Luntian Central', NULL, NULL, 'PM-2025-00214', 'Continuation application following the prior document.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00725', 1, 'Identity', 'FILE-385415', '2026-10-27', 'NeedsCorrection', '2026-11-02', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00725', 2, 'Registration', 'FILE-746037', '2026-10-31', 'NeedsCorrection', '2026-11-03', 'The recorded reference must be verified with the submitted copy.'),
('APP-2026-00725', 3, 'PriorPermit', 'PM-2025-00214', '2026-11-01', 'NeedsCorrection', '2026-11-03', 'The submitted name requires clarification against the application.');

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000708', 'APP-2026-00725', '2026-11-03', 750, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00726', 'AP-00038', 'GF-00163', '2026-10-28', 'New', 'UnderReview', NULL, 'LC03', 'Mabini East', 'ACQ-45638-26', '2026-09-22', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00726', 1, 'Identity', 'DOC-21940', '2026-10-28', 'Accepted', '2026-11-03', NULL),
('APP-2026-00726', 2, 'Registration', 'REF-408499', '2026-11-01', 'NeedsCorrection', '2026-11-03', 'The submitted name requires clarification against the application.'),
('APP-2026-00726', 3, 'Acquisition', 'ACQ-45638-26', '2026-10-30', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000709', 'APP-2026-00726', '2026-11-03', 350, 'BankTransfer'),
('OR-2026-000710', 'APP-2026-00726', '2026-10-28', 150, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00727', 'AP-00077', 'GF-00066', '2026-10-28', 'Renewal', 'Submitted', NULL, 'LC05', 'Santa Elena', NULL, NULL, 'PM-2026-00356', 'Regular renewal before the recorded validity ends.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00727', 1, 'Identity', 'DOC-38283', '2026-10-28', 'Pending', NULL, NULL),
('APP-2026-00727', 2, 'Registration', 'DOC-994265', '2026-11-02', 'Pending', NULL, NULL),
('APP-2026-00727', 3, 'PriorPermit', 'PM-2026-00356', '2026-10-28', 'Pending', NULL, NULL),
('APP-2026-00727', 4, 'Other', 'REF-954524', '2026-10-30', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000711', 'APP-2026-00727', '2026-10-29', 1200, 'Online');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00728', 'AP-00070', 'GF-00145', '2026-10-28', 'Renewal', 'Submitted', NULL, 'LC01', 'Luntian Central', NULL, NULL, 'PM-2026-00319', 'Applicant requests the next authorization period.', NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00728', 1, 'Identity', 'DOC-803995', '2026-10-28', 'Pending', NULL, NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000712', 'APP-2026-00728', '2026-11-02', 600, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00729', 'AP-00041', 'GF-00153', '2026-10-31', 'New', 'UnderReview', NULL, 'LC05', 'Santa Elena', 'ACQ-27738-26', '2026-07-11', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00729', 1, 'Identity', 'DOC-827426', '2026-10-31', 'Accepted', '2026-11-03', NULL),
('APP-2026-00729', 2, 'Registration', 'REF-317017', '2026-11-01', 'Accepted', '2026-11-03', NULL),
('APP-2026-00729', 3, 'Acquisition', 'ACQ-27738-26', '2026-11-03', 'Accepted', '2026-11-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000713', 'APP-2026-00729', '2026-11-03', 750, 'Cash');


INSERT INTO applications (app_no, appl_no, gun_no, appdate, appkind, appstat, decdate, loccode, locname, proofref, proofdt, prevperm, renwhy, lostdate, lossref) VALUES
('APP-2026-00730', 'AP-00138', 'GF-00117', '2026-10-31', 'New', 'UnderReview', NULL, 'LC01', 'Luntian Central', 'ACQ-52047-26', '2026-09-18', NULL, NULL, NULL, NULL);

INSERT INTO submissions (app_no, docseq, doccat, docref, recvdate, review, revdate, remarks) VALUES
('APP-2026-00730', 1, 'Identity', 'FILE-431044', '2026-10-31', 'Pending', NULL, NULL),
('APP-2026-00730', 2, 'Registration', 'DOC-179759', '2026-11-03', 'Accepted', '2026-11-03', NULL),
('APP-2026-00730', 3, 'Acquisition', 'ACQ-52047-26', '2026-11-03', 'Accepted', '2026-11-03', NULL);

INSERT INTO payments (rcpt_no, app_no, paydate, amount, paymode) VALUES
('OR-2026-000714', 'APP-2026-00730', '2026-11-03', 350, 'Cash');



COMMIT;
