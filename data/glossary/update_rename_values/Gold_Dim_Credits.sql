/*CASE c.[Кредиты Финансовый Продукт]
	     WHEN 'Credite auto denominate in Euro' THEN 'Auto Loans EUR'
         WHEN 'Credite ipotecare MDL' THEN 'Mortgage MDL'
         WHEN 'Credite auto denominate in moneda nationala' THEN 'Auto Loans Local'
         WHEN 'Credite ipotecare USD' THEN 'Mortgage USD'
         WHEN 'Creditare directa denominata in moneda Euro' THEN 'Direct Lending EUR'
         WHEN 'Credite pentru conditii de trai denominate in Euro' THEN 'Living Condition Loans EUR'
         WHEN 'Creditare directa denominata in moneda USD' THEN 'Direct Lending USD'
         WHEN 'Creditare directa denominata in moneda nationala' THEN 'Direct Lending Local'
         WHEN 'Creditarea in parteneriat cu comerciantii' THEN 'Partner Lending'
         WHEN 'Creditare auto' THEN 'Auto Loans'
         WHEN 'Credite studii  denominate in moneda nationala' THEN 'Study Loans Local'
         WHEN 'Credite calatorii  denominate in Eur' THEN 'Travel Loans EUR'
         WHEN 'Garantii financiare' THEN 'Financial Guarantees'
         WHEN 'Credite HIL denominate in moneda nationala' THEN 'HIL Loans Local'
         WHEN 'Credite  istorice in valuta ( pina la 23.05.2008)' THEN 'Historical Loans'
         WHEN 'Credite pentru conditii de trai denominate in moneda nationala' THEN 'Living Condition Loans Local'
         WHEN 'Credite Consumer Non-Business denominate in moneda nationala' THEN 'Consumer Loans Non-Business'
         WHEN 'Credite ipotecare EUR' THEN 'Mortgage EUR'
         WHEN 'Capital de risc' THEN 'Venture Capital'
         WHEN 'Credite work&travel denominate in moneda nationala' THEN 'Work&Travel Loans Local'
         WHEN 'Credite HIL denominate in Euro' THEN 'HIL Loans EUR'
         WHEN 'Credite work&travel denominate in USD' THEN 'Work&Travel Loans USD'
         WHEN 'Credite angajati' THEN 'Employee Loans'
         WHEN 'Creditare Asociatie' THEN 'Association Lending'
         WHEN 'Credite calatorii  denominate in moneda nationala' THEN 'Travel Loans Local'
         WHEN 'Credite pentru conditii de trai denominate in USD' THEN 'Living Condition Loans USD'
         WHEN 'Creditare in grup' THEN 'Group Lending'
         WHEN 'Credite auto denominate in USD' THEN 'Auto Loans USD'
		 ELSE  c.[Кредиты Финансовый Продукт]
	END AS FinancialProduct,*/
	
	/*CASE c.[Кредиты Валюта]
	     WHEN 'Lei' THEN 'MDL'
		 ELSE c.[Кредиты Валюта]
	END AS Currency,*/
	
	/*CASE c.[Кредиты Цель Кредита]
	     WHEN 'Altele pentru activitate de antreprenoriat/profesională' THEN 'Other Prof. Activity'
         WHEN 'Afacere Mijloace fixe' THEN 'Business Fixed Assets'
         WHEN 'Tratament' THEN 'Treatment'
         WHEN 'Procurare Imobil (teren sau constructii)' THEN 'Real Estate'
         WHEN 'Altele' THEN 'Other'
         WHEN 'Vacanta' THEN 'Vacation'
         WHEN 'Refinantarea creditelor alte comp/p.f.' THEN 'Loan Refinancing'
         WHEN 'Mixt cu Refinantare' THEN 'Mixed w/ Refinancing'
         WHEN 'Mijloace fixe' THEN 'Fixed Assets'
         WHEN 'Mixt' THEN 'Mixed'
         WHEN 'Formare /rambursare împrumut față de fondator' THEN 'Loan to Founder'
         WHEN 'Refinantare MI' THEN 'MI Refinancing'
         WHEN 'Materiale de Constructie (reparatii, renovări si reconstructii)' THEN 'Construction Mat.'
         WHEN 'Refinantare institutilor terte (si altele) prin viramente' THEN '3rd Party Refin.'
         WHEN 'Autoturism' THEN 'Car'
         WHEN 'Mixt Mijloace Circulante' THEN 'Mixed Current Assets'
         WHEN 'Mobilier (categoria medie)' THEN 'Furniture'
         WHEN 'Echipament pt Gospodarie' THEN 'Household Equip.'
         WHEN 'Mediere' THEN 'Mediation'
         WHEN 'Conditii de trai' THEN 'Living Cond.'
         WHEN 'Alte imbunatatiri ale conditiilor de trai' THEN 'Living Improvements'
         WHEN 'Formare /rambursare împrumut față de fondator / PF' THEN 'Loan to Founder/Ind.'
         WHEN 'Mixt retroactive' THEN 'Retroactive Mixed'
         WHEN 'Studii' THEN 'Studies'
         WHEN 'Gadgeturi' THEN 'Gadgets'
         WHEN 'Mixt cu Refinantare MI' THEN 'Mixed w/ MI Refin.'
         WHEN 'Fix retroactive' THEN 'Retroactive Fixed'
         WHEN 'Sisteme de Incalzire,conditionare, apa Canalizare' THEN 'HVAC & Water'
         WHEN 'Ceremonii/ Eveniment organizat' THEN 'Event / Ceremony'
         WHEN 'Mijloace circulante' THEN 'Current Assets'
         WHEN 'Electrocasnice (Echipament si sisteme electrice)' THEN 'Appliances'
         WHEN 'Nevoi personale' THEN 'Personal Needs'
         WHEN 'Finantare retail' THEN 'Retail Financing'
         WHEN 'Afacere Mijloace circulante' THEN 'Business Curr. Assets'
         WHEN 'Mixt cu refinantare prin compensare' THEN 'Mixed Offset Refin.'
         WHEN 'Necesitati curente' THEN 'Current Necessities'
         WHEN 'Necesitati personale' THEN 'Personal Necessities'
         WHEN 'Mixt cu esalonare/preluare' THEN 'Mixed Installments'
		 ELSE c.[Кредиты Цель Кредита]
	END AS Purpose,*/
	
	/*CASE c.[Кредиты Сегмент Доходов]
         WHEN 'Business Rapid MDL' THEN 'Business Rapid MDL'
         WHEN 'Consum & HAI' THEN 'Consumer & HAI'
         WHEN 'Retail fără comisioane' THEN 'Retail No Fees'
         WHEN 'Altele' THEN 'Other'
         WHEN 'FX Consum & HAI' THEN 'FX Consumer & HAI'
         WHEN 'FX Creditare Auto' THEN 'FX Auto Loan'
         WHEN 'Linia de credit retail' THEN 'Retail Credit Line'
         WHEN 'Retail Standart 2/4%' THEN 'Retail Standard 2/4%'
         WHEN 'Retail Standart' THEN 'Retail Standard'
         WHEN 'HIL clienti business' THEN 'HIL Business Clients'
         WHEN 'Retail standard 5/9%' THEN 'Retail Standard 5/9%'
         WHEN 'HIL cu gaj clienti business' THEN 'HIL Pledged Business'
         WHEN 'FX Business Oferta Afaceri' THEN 'FX Business Offer'
         WHEN 'Creditare Auto' THEN 'Auto Loan'
         WHEN 'HIL' THEN 'HIL'
         WHEN 'Consum clienti business' THEN 'Business Consumer'
         WHEN 'Retail Mixt' THEN 'Retail Mixed'
         WHEN 'Business Creditare Directă' THEN 'Business Direct Loan'
         WHEN 'Ipoteca FX' THEN 'FX Mortgage'
         WHEN 'Ipoteca' THEN 'Mortgage'
         WHEN 'FX Business Partners' THEN 'FX Business Partners'
         WHEN 'Mediere' THEN 'Mediation'
         WHEN 'Retail Gratie Comision' THEN 'Retail Comision Free'
         WHEN 'B2B Partners EUR' THEN 'B2B Partners EUR'
         WHEN 'Retail 0%' THEN 'Retail 0%'
         WHEN 'B2B Partners MDL' THEN 'B2B Partners MDL'
         WHEN 'Business partners' THEN 'Business Partners'
         WHEN 'HIL FX clienti business' THEN 'HIL FX Business'
         WHEN 'Online Cash' THEN 'Online Cash'
         WHEN 'Consum FX clienti business' THEN 'FX Consumer Business'
         WHEN 'Business Rapid EUR' THEN 'Business Rapid EUR'
         WHEN 'Retail Double' THEN 'Retail Double'
         WHEN 'HIL cu gaj' THEN 'HIL Pledged'
         WHEN 'Consum non-business' THEN 'Non-Business Consumer'
         WHEN 'FX Business Creditare Directă' THEN 'FX Business Direct Loan'
         ELSE c.[Кредиты Сегмент Доходов]
    END AS IncomeSegment,*/
	
	/*CASE c.[Кредиты Назначение Использования Кредита]
		 WHEN 'Antreprenor' THEN 'Bussines'
		 WHEN 'Necesitati personale' THEN 'Personal Needs'
		 ELSE c.[Кредиты Назначение Использования Кредита]
	END AS UsagePurpose,*/	 	
	
	 /*CASE c.[Кредиты Тип Кредитного Продукта]
	     WHEN 'Dezvoltarea afacerii' THEN 'Business Development'
         WHEN 'Credit prin partener' THEN 'Partner Loan'
         WHEN 'Procurare imobil' THEN 'Property Purchase'
         WHEN 'Credit' THEN 'Loan'
         WHEN 'Procurare automobil' THEN 'Car Purchase'
         WHEN 'Linia de credit' THEN 'Credit Line'
         WHEN 'Necesitati curente' THEN 'Current Needs'
		 ELSE c.[Кредиты Тип Кредитного Продукта]
	END AS ProductType,*/ 
	
	/*CASE c.[Кредиты Сфера Использования Кредита]
         WHEN 'Constructiile' THEN 'Construction'
         WHEN 'Altele' THEN 'Other'
         WHEN 'Comert' THEN 'Trade'
         WHEN 'Prestarea serviciilor' THEN 'Services'
         WHEN 'Transport si Telecomunicatii' THEN 'Transport & Telecom'
         WHEN 'Agricultura' THEN 'Agriculture'
         WHEN 'Ipoteca' THEN 'Mortgage'
         WHEN 'Industria alimentara' THEN 'Food Industry'
         WHEN 'Consum' THEN 'Consumption'
         WHEN 'Antreprenori' THEN 'Entrepreneurs'
         WHEN 'Industria energetica' THEN 'Energy Industry'
         WHEN 'Producere' THEN 'Manufacturing'
		 ELSE c.[Кредиты Сфера Использования Кредита]
	END AS UsageArea,*/
	
	
	/*CASE fp.FinancialProductsMainGroup
	     WHEN 'Creditare Retail' THEN 'Retail Credit'
		 WHEN 'Mediere' THEN 'Mediation'
		 WHEN 'REPLACE Credite istorice' THEN 'Replace Historical Credits'
         WHEN 'Restructurare' THEN 'Restructuring'
		 ELSE fp.FinancialProductsMainGroup
	END AS FinancialProductsMainGroup,*/
	
	/*CASE seg.SegmentRevenue
	     WHEN 'Business Rapid MDL' THEN 'Biz Rapid MDL'
         WHEN 'Consum & HAI' THEN 'Cons & HAI'
         WHEN 'Retail fără comisioane' THEN 'Retail No Fee'
         WHEN 'Altele' THEN 'Other'
         WHEN 'FX Consum & HAI' THEN 'FX Cons & HAI'
         WHEN 'FX Creditare Auto' THEN 'FX Auto Credit'
         WHEN 'Linia de credit retail' THEN 'Retail Credit Line'
         WHEN 'Retail Standart 2/4%' THEN 'Retail Std 2/4%'
         WHEN 'Retail Standart' THEN 'Retail Std'
         WHEN 'HIL clienti business' THEN 'HIL Biz Clients'
         WHEN 'Retail standard 5/9%' THEN 'Retail Std 5/9%'
         WHEN 'HIL cu gaj clienti business' THEN 'HIL Secured Biz Clients'
         WHEN 'FX Business Oferta Afaceri' THEN 'FX Biz Offer'
         WHEN 'HIL' THEN 'HIL'
         WHEN 'Creditare Auto' THEN 'Auto Credit'
         WHEN 'Consum clienti business' THEN 'Cons Biz Clients'
         WHEN 'Retail Mixt' THEN 'Retail Mixed'
         WHEN 'Business Creditare Directă' THEN 'Biz Direct Credit'
         WHEN 'Ipoteca FX' THEN 'FX Mortgage'
         WHEN 'Business Oferta Specială Agro' THEN 'Biz Agro Special Offer'
         WHEN 'Ipoteca' THEN 'Mortgage'
         WHEN 'FX Business Partners' THEN 'FX Biz Partners'
         WHEN 'Mediere' THEN 'Mediation'
         WHEN 'Retail Gratie Comision' THEN 'Retail Fee Waived'
         WHEN 'B2B Partners EUR' THEN 'B2B Partners EUR'
         WHEN 'Retail 0%' THEN 'Retail 0%'
         WHEN 'B2B Partners MDL' THEN 'B2B Partners MDL'
         WHEN 'Business partners' THEN 'Biz Partners'
         WHEN 'HIL FX clienti business' THEN 'HIL FX Biz Clients'
         WHEN 'Online Cash' THEN 'Online Cash'
         WHEN 'Consum FX clienti business' THEN 'Cons FX Biz Clients'
         WHEN 'Business Rapid EUR' THEN 'Biz Rapid EUR'
         WHEN 'Retail Double' THEN 'Retail Double'
         WHEN 'HIL cu gaj' THEN 'HIL Secured'
         WHEN 'Consum non-business' THEN 'Cons Non-Biz'
         WHEN 'FX Business Creditare Directă' THEN 'FX Biz Direct Credit'
		 ELSE seg.SegmentRevenue
	END AS SegmentRevenue ,*/
	
	/*CASE gc.CommitteeProt_CrPurpose
		 WHEN 'Antreprenor' THEN 'Bussines'
		 WHEN 'Necesitati personale' THEN 'Personal Needs'
         ELSE  gc.CommitteeProt_CrPurpose
    END AS CommitteeProt_CrPurpose,*/ 
	