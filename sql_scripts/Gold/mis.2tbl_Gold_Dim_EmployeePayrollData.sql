USE [ATK];
GO

-- Drop table if exists
IF OBJECT_ID('mis.[2tbl_Gold_Dim_EmployeePayrollData]', 'U') IS NOT NULL
    DROP TABLE mis.[2tbl_Gold_Dim_EmployeePayrollData];
GO

-- Create table
CREATE TABLE mis.[2tbl_Gold_Dim_EmployeePayrollData]
(
    EmployeePositionID VARCHAR(36) NOT NULL,
    EmployeePosition NVARCHAR(150) NULL
);
GO

-- Insert normalized and mapped positions
INSERT INTO mis.[2tbl_Gold_Dim_EmployeePayrollData] 
(
    EmployeePositionID,
    EmployeePosition
)
SELECT 
    [СотрудникиДанныеПоЗарплате Должность ID] AS EmployeePositionID,
	[СотрудникиДанныеПоЗарплате Должность] AS EmployeePosition
    /*CASE [СотрудникиДанныеПоЗарплате Должность]
        WHEN 'consilier juridic/consilieră juridică' THEN 'Legal Advisor'
        WHEN 'sofer autobuz' THEN 'Bus Driver'
        WHEN 'contabil-sef' THEN 'Chief Accountant'
        WHEN 'director comercial' THEN 'Commercial Director'
        WHEN 'expert' THEN 'Expert'
        WHEN 'manager (in serviciile de informatii si reclama)' THEN 'Manager (Information and Advertising Services)'
        WHEN 'coordonator de proiecte' THEN 'Project Coordinator'
        WHEN 'specialist imbunatatire procese' THEN 'Process Improvement Specialist'
        WHEN 'contabil-şef/contabilă-șefă' THEN 'Chief Accountant'
        WHEN 'secretar asistent director' THEN 'Executive Assistant'
        WHEN 'manager relații financiare' THEN 'Financial Relations Manager'
        WHEN 'avocat' THEN 'Lawyer'
        WHEN 'specialist ocrotirea informatiei' THEN 'Information Security Specialist'
        WHEN 'administrator sisteme informatice' THEN 'IT Sys Admin'
        WHEN 'administrator/administratoare de sisteme' THEN 'Sys Admin'
        WHEN 'auditor' THEN 'Auditor'
        WHEN 'manager de proiect' THEN 'Project Manager'
        WHEN 'arhivar' THEN 'Archivist'
        WHEN 'manager (in activitatea comerciala)' THEN 'Commercial Manager'
        WHEN 'analist/analistă credite' THEN 'Credit Analyst'
        WHEN 'muncitor auxiliar' THEN 'Auxiliary Worker'
        WHEN 'contabil-expert' THEN 'Expert Accountant'
        WHEN 'fotograf' THEN 'Photographer'
        WHEN 'functionar documentare' THEN 'Documentation Clerk'
        WHEN 'casier expert' THEN 'Expert Cashier'
        WHEN 'consilier juridic' THEN 'Legal Counselor'
        WHEN 'colector/colectoare creanțe' THEN 'Debt Collector'
        WHEN 'administrator credite' THEN 'Credit Administrator'
        WHEN 'operator ghiseu banca' THEN 'Bank Teller'
        WHEN 'specialist/specialistă' THEN 'Specialist'
        WHEN 'consultant/consultantă' THEN 'Consultant'
        WHEN 'sef sectie (dezvoltare tehnico-stiintifica)' THEN 'Head of Section (Scientific Development)'
        WHEN 'ingrijitor incaperi de productie si de serviciu' THEN 'Production and Service Room Cleaner'
        WHEN 'specialist resurse umane' THEN 'HR Specialist'
        WHEN 'economist/economistă' THEN 'Economist'
        WHEN 'analist credite' THEN 'Credit Analyst'
        WHEN 'director executiv' THEN 'Executive Director'
        WHEN 'expert financiar-bancar' THEN 'Financial-Banking Expert'
        WHEN 'masinist (fochist) in sala de cazane' THEN 'Boiler Room Operator'
        WHEN 'specialist/specialistă în management și organizare' THEN 'Management and Organization Specialist'
        WHEN 'manager de formare' THEN 'Training Manager'
        WHEN 'sef  departament/directie/sectie in asociatie, uniune, federatie' THEN 'Department Head in Association/Union/Federation'
        WHEN 'jurisconsult/jurisconsultă' THEN 'Legal Consultant'
        WHEN 'manager de oficiu' THEN 'Office Manager'
        WHEN 'expert in certificare' THEN 'Certification Expert'
        WHEN 'șef/șefă' THEN 'Head/Chief'
        WHEN 'jurisconsult' THEN 'Legal Consultant'
        WHEN 'coordonator/coordonatoare' THEN 'Coordinator'
        WHEN 'șef/șefă secție' THEN 'Section Head'
        WHEN 'îngrijitor/îngrijitoare încăperi' THEN 'Room Cleaner'
        WHEN 'manager imbunatatire procese' THEN 'Process Improvement Manager'
        WHEN 'director (sef) filiala' THEN 'Branch Director'
        WHEN 'manager (in alte ramuri)' THEN 'Manager (Other Fields)'
        WHEN 'manager (in servicii de personal, pregatirea personalului si alte relatii de munca)' THEN 'HR and Training Manager'
        WHEN 'șef/șefă departament' THEN 'Department Head'
        WHEN 'conducător/conducătoare auto' THEN 'Driver'
        WHEN 'specialist control risc' THEN 'Risk Control Specialist'
        WHEN 'conducator auto (șofer)' THEN 'Driver'
        WHEN 'asistent programator' THEN 'Programmer Assistant'
        WHEN 'expert/expertă' THEN 'Expert'
        WHEN 'ofice-manager' THEN 'Office Manager'
        WHEN 'funcționar administrativ/funcționară administrativă' THEN 'Administrative Clerk'
        WHEN 'curier' THEN 'Courier'
        WHEN 'referent/referentă' THEN 'Referent'
        WHEN 'specialist/specialistă în securitatea informației' THEN 'Information Security Specialist'
        WHEN 'muncitor auxiliar/muncitoare auxiliară' THEN 'Auxiliary Worker'
        WHEN 'director executiv/directoare executivă' THEN 'Executive Director'
        WHEN 'funcţionar/funcționară informaţii clienţi/cliente' THEN 'Customer Service Officer'
        WHEN 'director (sef) departament' THEN 'Department Director'
        WHEN 'manager (in alte compartimente [servicii] functionale)' THEN 'Functional Area Manager'
        WHEN 'sef departament banca' THEN 'Bank Department Head'
        WHEN 'agent de vinzari' THEN 'Sales Agent'
        WHEN 'programator/programatoare' THEN 'Programmer'
        WHEN 'sef sectie' THEN 'Section Head'
        WHEN 'arhitect/arhitectă de sisteme' THEN 'System Architect'
        WHEN 'specialist marketing' THEN 'Marketing Specialist'
        WHEN 'casier' THEN 'Cashier'
        WHEN 'manager proiect' THEN 'Project Manager'
        WHEN 'sef sectie (informatica)' THEN 'IT Section Head'
        WHEN 'șef/șefă secție în domeniul administrativ' THEN 'Administrative Section Head'
        WHEN 'referent' THEN 'Referent'
        WHEN 'sef directie (specializata in alte ramuri)' THEN 'Director (Other Specialized Branches)'
        WHEN 'specialist/specialistă în îmbunătăţirea proceselor' THEN 'Process Improvement Specialist'
        WHEN 'maturator' THEN 'Cleaner'
        WHEN 'auditor intern/auditoare internă' THEN 'Internal Auditor'
        WHEN 'consilier financiar-bancar' THEN 'Financial-Banking Advisor'
        WHEN 'contabil' THEN 'Accountant'
        WHEN 'director general intreprindere' THEN 'General Director'
        WHEN 'manager (in compartimentele de dezvoltare stiintifico-tehnica)' THEN 'R&D Manager'
        WHEN 'interpret' THEN 'Interpreter'
        WHEN 'director/directoare' THEN 'Director'
        WHEN 'presedinte consiliu (tehnico-stiintific, didactico-metodic, stiintific (medical-metodic), de cultura' THEN 'Council President (Scientific/Methodical/Cultural)'
        WHEN 'programator' THEN 'Programmer'
        WHEN 'administrator' THEN 'Administrator'
        WHEN 'director (sef, imputernicit) directie' THEN 'Director (Authorized/Head of Department)'
        WHEN 'secretara' THEN 'Secretary'
        WHEN 'administrator/administratoare de credite' THEN 'Credit Administrator'
        WHEN 'specialist/specialistă în domeniul bancar/nebancar' THEN 'Banking/Non-Banking Specialist'
        WHEN 'manager de produs' THEN 'Product Manager'
        WHEN 'ofițer antifraudă financiar-bancară' THEN 'Financial Anti-Fraud Officer'
        WHEN 'funcționar/funcționară de birou' THEN 'Office Clerk'
        WHEN 'contabil/contabilă' THEN 'Accountant'
        WHEN 'sef serviciu (specializat in alte ramuri)' THEN 'Service Head (Other Fields)'
        WHEN 'operator in sectia de pregatire' THEN 'Preparation Section Operator'
    ELSE [СотрудникиДанныеПоЗарплате Должность]
END AS EmployeePosition
*/

FROM [ATK].[dbo].[РегистрыСведений.СотрудникиДанныеПоЗарплате];
GO
