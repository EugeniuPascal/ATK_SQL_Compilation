USE [ATK];
GO


-- Consilier Juridic/Consilieră Juridică → Legal Advisor
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Legal Advisor'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Consilier Juridic/Consilieră Juridică';

-- IT Sys Admin
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'IT Sys Admin'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Administrator sisteme informatice';

-- Product Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Product Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager de produs';

-- Director
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Director'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Director';

-- Financial-Banking Expert
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Financial-Banking Expert'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Expert financiar-bancar';

-- R&D Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'R&D Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager (in compartimentele de dezvoltare stiintifico-tehnica)';

-- Bank Department Head
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Bank Department Head'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Sef departament banca';

-- Director (Authorized/Head of Department)
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Director (Authorized/Head of Department)'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Director (sef, imputernicit) directie';

-- Expert
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Expert'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Expert';

-- Archivist
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Archivist'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Arhivar';

-- Service Head (Other Fields)
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Service Head (Other Fields)'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Sef serviciu (specializat in alte ramuri)';

-- Contabil-şef/Contabilă-șefă → Chief Accountant
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Chief Accountant'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Contabil-şef/Contabilă-șefă';

-- Credit Analyst
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Credit Analyst'
WHERE EmployeePosition COLLATE Romanian_CI_AS IN ('Analist/Analistă credite', 'Analist credite');

-- Manager relații financiare → Financial Relations Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Financial Relations Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager relații financiare';

-- Commercial Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Commercial Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager (in activitatea comerciala)';

-- Legal Counselor
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Legal Counselor'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Consilier juridic';

-- Cashier
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Cashier'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Casier';

-- Project Coordinator
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Project Coordinator'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Coordonator de proiecte';

-- Consultant
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Consultant'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Consultant/Consultantă';

-- General Director
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'General Director'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Director general intreprindere';

-- Auditor
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Auditor'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Auditor';

-- Lawyer
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Lawyer'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Avocat';

-- Cleaner
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Cleaner'
WHERE EmployeePosition COLLATE Romanian_CI_AS IN ('Muncitor auxiliar', 'Maturator');

-- Section Head
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Section Head'
WHERE EmployeePosition COLLATE Romanian_CI_AS IN ('Șef/Șefă Secție', 'Sef sectie');

-- Process Improvement Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Process Improvement Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager imbunatatire procese';

-- Expert Accountant
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Expert Accountant'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Contabil-expert';

-- Commercial Director
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Commercial Director'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Director comercial';

-- Certification Expert
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Certification Expert'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Expert in certificare';

-- Chief Accountant
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Chief Accountant'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Contabil-şef/Contabilă-șefă';

-- Manager (Information and Advertising Services)
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Manager (Information and Advertising Services)'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager (in serviciile de informatii si reclama)';

-- Information Security Specialist
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Information Security Specialist'
WHERE EmployeePosition COLLATE Romanian_CI_AS IN ('Specialist ocrotirea informatiei', 'Specialist/specialistă în securitatea informației');

-- Accountant
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Accountant'
WHERE EmployeePosition COLLATE Romanian_CI_AS IN ('Contabil', 'Contabil/Contabilă');

-- Colector/Colectoare creanțe → Debt Collector
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Debt Collector'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Colector/Colectoare creanțe';

-- Branch Director
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Branch Director'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Director (sef) filiala';

-- Specialist/Specialistă
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Specialist'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Specialist/Specialistă';

-- Coordinator
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Coordinator'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Coordonator/Coordonatoare';

-- NULL (keep as NULL)
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = NULL
WHERE EmployeePosition IS NULL;

-- Director (Other Specialized Branches)
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Director (Other Specialized Branches)'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Sef directie (specializata in alte ramuri)';

-- Economist/Economistă → Economist
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Economist'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Economist/Economistă';

-- Manager → Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager';

-- Secretary
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Secretary'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Secretara';

-- Specialist/specialistă în management și organizare
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Management and Organization Specialist'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Specialist/specialistă în management și organizare';

-- Sys Admin
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Sys Admin'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Administrator/Administratoare de sisteme';

-- Jurisconsult/Jurisconsultă → Legal Consultant
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Legal Consultant'
WHERE EmployeePosition COLLATE Romanian_CI_AS IN ('Jurisconsult', 'Jurisconsult/Jurisconsultă');

-- Boiler Room Operator
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Boiler Room Operator'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Masinist (fochist) in sala de cazane';

-- Documentation Clerk
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Documentation Clerk'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Functionar documentare';

-- Head of Section (Scientific Development)
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Head of Section (Scientific Development)'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Sef sectie (dezvoltare tehnico-stiintifica)';

-- Șef/Șefă → Head/Chief
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Head/Chief'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Șef/Șefă';

-- Executive Director
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Executive Director'
WHERE EmployeePosition COLLATE Romanian_CI_AS IN ('Director executiv', 'Director Executiv/Directoare Executivă');

-- Șef/Șefă Secție → Section Head
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Section Head'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Șef/Șefă Secție';

-- Îngrijitor/îngrijitoare încăperi → Room Cleaner
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Production and Service Room Cleaner'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Îngrijitor/îngrijitoare încăperi';

-- Programmer Assistant
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Programmer Assistant'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Asistent programator';

-- Programmer
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Programmer'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Programator';

-- Șef/Șefă Departament → Department Head
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Department Head'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Șef/Șefă Departament';

-- Conducător/Conducătoare Auto → Driver
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Driver'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Conducător/Conducătoare Auto';

-- Council President (Scientific/Methodical/Cultural)
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Council President (Scientific/Methodical/Cultural)'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Președinte consiliu (tehnico-știintific, didactico-metodic, știintific (medical-metodic), de cultura)';

-- Sales Agent
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Sales Agent'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Agent de vinzari';

-- Financial-Banking Advisor
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Financial-Banking Advisor'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Consilier financiar-bancar';

-- Department Head in Association/Union/Federation
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Department Head in Association/Union/Federation'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Sef  departament/directie/sectie in asociatie, uniune, federatie';

-- Conducator auto (șofer) → Driver
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Driver'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Conducator auto (șofer)';

-- Legal Consultant
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Legal Consultant'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Jurisconsult/Jurisconsultă';

-- Photographer
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Photographer'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Fotograf';

-- Expert/Expertă → Expert
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Expert'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Expert/Expertă';

-- HR and Training Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'HR and Training Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager (in servicii de personal, pregatirea personalului si alte relatii de munca)';

-- Project Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Project Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager de Proiect';

-- Funcționar Administrativ/Funcționară Administrativă
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Administrative Clerk'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Funcționar Administrativ/Funcționară Administrativă';

-- Referent/referentă → Clerk
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Clerk'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Referent/referentă';

-- Specialist/specialistă în securitatea informației
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Information Security Specialist'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Specialist/specialistă în securitatea informației';

-- Muncitor auxiliar/muncitoare auxiliară → Auxiliary Worker
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Auxiliary Worker'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Muncitor auxiliar/muncitoare auxiliară';

-- HR Specialist
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'HR Specialist'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Specialist resurse umane';

-- Director Executiv/Directoare Executivă → Executive Director
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Executive Director'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Director Executiv/Directoare Executivă';

-- Funcţionar/funcționară informaţii clienţi/cliente → Customer Info Clerk
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Customer Info Clerk'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Funcţionar/funcționară informaţii clienţi/cliente';

-- Functional Area Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Functional Area Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager (in alte compartimente [servicii] functionale)';

-- Manager (Other Fields)
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Manager (Other Fields)'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager (Other Fields)';

-- Bank Teller
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Bank Teller'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Casier';

-- Training Manager
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Training Manager'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Manager de formare';

-- Bus Driver
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Bus Driver'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Șofer autobuz';

-- Auxiliary Worker
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Auxiliary Worker'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Muncitor auxiliar/muncitoare auxiliară';

-- Credit Administrator
UPDATE [mis].[2tbl_Gold_Dim_EmployeePayrollData]
SET EmployeePosition = 'Credit Administrator'
WHERE EmployeePosition COLLATE Romanian_CI_AS = 'Administrator/Administra]]
