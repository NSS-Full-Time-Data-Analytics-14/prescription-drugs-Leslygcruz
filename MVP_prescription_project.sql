-- There is DUPLICATION in the drugs table.  
-- SELECT COUNT(drug_name) FROM drug. 3425 drug names
SELECT COUNT(drug_name)
FROM drug;
-- SELECT COUNT (DISTINCT drug_name) FROM drug. 3253 drug names
SELECT COUNT(DISTINCT drug_name)
FROM drug;
-- Notice the difference? 172 drug name diff 
-- You can investigate further and then be sure to consider the duplication when joining to the drug table.
SELECT npi, drug_name, total_claim_count
FROM prescription;

-- 1a. Which prescriber had the highest total number of claims 
-- (totaled over all drugs)?
-- Report the npi and the total number of claims. 
-- ANS: npi:1356305197, 379 claims
SELECT npi,COUNT(total_claim_count) AS total_claim_count
FROM prescription
-- WHERE drug_name IN
-- 	(SELECT DISTINCT(drug_name)
-- 		FROM prescription)
GROUP BY npi
ORDER BY total_claim_count DESC;
-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,
-- specialty_description, and the total number of claims.
-- ANS: npi:1356305197	total_claim_count:379, first name:"MICHAEL"
-- las org name:"COX", specialty_description: "Internal Medicine"
SELECT ps.npi, COUNT(ps.total_claim_count)AS total_claim_count,
		pb.nppes_provider_first_name, pb.nppes_provider_last_org_name,pb.specialty_description
FROM prescription AS ps
INNER JOIN prescriber AS pb
USING(npi)
-- WHERE ps.drug_name IN
-- 	(SELECT DISTINCT drug_name
-- 	FROM prescription)
GROUP BY ps.npi, pb.nppes_provider_first_name, pb.nppes_provider_last_org_name,pb.specialty_description
ORDER BY total_claim_count DESC;

--2a. Which specialty had the most total number of claims (totaled over all drugs)?
-- ANS: FAMILY PRACTICE 9752347 claims
SELECT pb.specialty_description, SUM(ps.total_claim_count) AS total_claim_count
FROM prescriber AS pb
INNER JOIN prescription AS ps
USING(npi)
-- WHERE drug_name IN
-- 	(SELECT drug_name
-- 	FROM prescription)
GROUP BY pb.specialty_description
ORDER BY total_claim_count DESC;
--     2b. Which specialty had the most total number of claims for opioids?
-- ANS: Nurse Practitioner
SELECT pb.specialty_description, SUM(ps.total_claim_count) AS total_claim_for_opiods
FROM prescriber AS pb
	INNER JOIN prescription AS ps
	USING(npi)
		INNER JOIN drug AS d
		USING(drug_name)
WHERE 
-- ps.drug_name IN
-- 	(SELECT DISTINCT drug_name
-- 	FROM prescription) 
-- 	AND
	d.opioid_drug_flag = 'Y'
GROUP BY pb.specialty_description
ORDER BY total_claim_for_opiods DESC;

--2c. **Challenge Question:** 
-- Are there any specialties that appear in the prescriber table that have
-- no associated prescriptions in the prescription table?
-- "Developmental Therapist", "Undefined Physician type", "Chiropractic"
-- "Marriage & Family Therapist", "Specialist/Technologist, Other", "Medical Genetics"
-- "Hospital","Physical Therapist in Private Practice","Radiology Practitioner Assistant"
-- "Ambulatory Surgical Center","Occupational Therapist in Private Practice"
-- "Physical Therapy Assistant","Licensed Practical Nurse","Midwife","Contractor"
SELECT specialty_description, SUM(total_claim_count) AS total_num_of_prescriptions
FROM prescriber
LEFT JOIN prescription
USING (npi)
GROUP BY specialty_description
ORDER BY total_num_of_prescriptions DESC;
--2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
-- For each specialty, report the percentage of total claims by that specialty which are for opioids.
-- Which specialties have a high percentage of opioids?
-- SELECT specialty_description, 
-- FROM prescriber AS pb
-- INNER JOIN prescription AS ps
-- USING(npi)
-- WHERE(SELECT SUM(total_claim_count)
-- 		FROM prescription
-- 		INNER JOIN drug
-- 		USING (drug_name)
-- 		WHERE opioid_drug_flag = 'Y')
-- GROUP BY specialty_description;

WITH num_of_opioid_claim_count AS (SELECT specialty_description, SUM(total_claim_count) AS opioid_count
									FROM prescription
									INNER JOIN drug
									USING (drug_name)
									INNER JOIN prescriber
									USING(npi)
									WHERE opioid_drug_flag = 'Y'
									GROUP BY specialty_description)
	-- total_claim_count AS(SELECT  SUM(total_claim_count)
	-- 					FROM prescription)
SELECT pb.specialty_description, ROUND((opioid_count/SUM(total_claim_count)*100),2) AS perc_of_opioid
FROM prescriber AS pb
INNER JOIN prescription AS ps
USING(npi)
INNER JOIN num_of_opioid_claim_count
USING (specialty_description)
GROUP BY specialty_description, opioid_count;
-- SELECT SUM(total_claim_count)
-- FROM prescription
-- INNER JOIN drug
-- WHERE opiod_drug_flag = 'Y'


--3a. Which drug (generic_name) had the highest total drug cost?
-- ANS: ESBRIET
SELECT npi, drug_name, SUM(total_drug_cost) AS highest_total_drug_cost
FROM prescription
GROUP BY npi,drug_name
ORDER BY highest_total_drug_cost DESC;

-- 3b. Which drug (generic_name) has the hightest total cost per day? 
-- **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
-- ANS: "GAMMAGARD LIQUID" $7141.11 daily cost
SELECT npi, drug_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2)  AS highest_total_cost_per_day
FROM prescription
GROUP BY npi, drug_name
ORDER BY highest_total_cost_per_day DESC;


-- 4a. For each drug in the drug table,
-- return the drug name and then a column named 'drug_type'
-- which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
-- says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
-- and says 'neither' for all other drugs. 
-- **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END drug_type
FROM drug;

-- 4b.Building off of the query you wrote for part a,
-- determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
-- Hint: Format the total costs as MONEY for easier comparision.
-- ANS: "$105,080,626.37" OPIOID
SELECT SUM(ps.total_drug_cost::money) AS total_drug_cost,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END drug_type
FROM drug AS d
INNER JOIN prescription AS ps
USING(drug_name)
GROUP BY drug_type
ORDER BY total_drug_cost DESC;

-- 5a. How many CBSAs are in Tennessee? 
-- **Warning:** The cbsa table contains information for all states,
-- not just Tennessee.
ANS: 42
SELECT state,COUNT(CAST (cbsa AS INT)) AS CBSA
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN'
GROUP BY state;

-- 5b. Which cbsa has the largest combined population? 
-- Which has the smallest? Report the CBSA name and total population.
-- ANS: cbsaname: "Memphis, TN-MS-AR",	pop:937847
SELECT cbsaname, population
FROM cbsa AS c
INNER JOIN population
USING(fipscounty)
ORDER BY population DESC;

-- 5c. What is the largest (in terms of population) county which is not included in a CBSA?
-- Report the county name and population.
-- ANS: name: WHITE, pop: 26394
SELECT p.fipscounty, p.population, fc.county
FROM population AS p
INNER JOIN fips_county AS fc
USING(fipscounty)
WHERE fipscounty NOT IN
	(SELECT fipscounty
	FROM cbsa)
ORDER BY fipscounty DESC;

-- 6a. Find all rows in the prescription table where total_claims is at least 3000.
-- Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

-- 6b. For each instance that you found in part a,
-- add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug AS d
USING(drug_name)
WHERE total_claim_count >= 3000;

--6c. Add another column to you answer from the previous part which gives the 
-- prescriber first and last name associated with each row.
SELECT nppes_provider_first_name, nppes_provider_last_org_name, drug_name, total_claim_count, opioid_drug_flag
FROM prescription
INNER JOIN drug AS d
USING(drug_name)
INNER JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000;

