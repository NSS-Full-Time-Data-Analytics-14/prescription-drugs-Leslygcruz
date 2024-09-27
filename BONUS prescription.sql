-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
-- ANS: 4458 npi numbers
SELECT npi
FROM prescriber
EXCEPT
SELECT npi
FROM prescription;

-- 2a. Find the top five drugs (generic_name) prescribed by prescribers 
-- with the specialty of Family Practice.
-- ANS: "OXYCODONE HCL"	4538
SELECT drug_name, total_claim_count
FROM prescription
INNER JOIN prescriber
USING(npi)
WHERE prescriber.specialty_description = 'Family Practice'
ORDER BY total_claim_count DESC;

-- 2b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
-- ANS: "ATORVASTATIN CALCIUM"	1952
SELECT drug_name, total_claim_count
FROM prescription
INNER JOIN prescriber
USING(npi)
WHERE prescriber.specialty_description = 'Cardiology'
ORDER BY total_claim_count DESC;

-- 2c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
-- Combine what you did for parts a and b into a single query to answer this question.
SELECT ps.drug_name, ps.total_claim_count
FROM prescription AS ps
INNER JOIN prescriber AS pb
USING (npi)
WHERE pb.specialty_description = 'Family Practice'
	OR pb.specialty_description = 'Cardiology'
ORDER BY total_claim_count DESC;

-- 3.Your goal in this question is to generate a list of the top 
-- prescribers in each of the major metropolitan areas of Tennessee.
SELECT npi, drug_name, total_claim_count, nppes_provider_city,
RANK()OVER(PARTITION BY npi ORDER BY total_claim_count DESC) AS npi_rank
FROM prescription
INNER JOIN prescriber
USING(npi)
WHERE nppes_provider_city ILIKE '%Nashville%'
LIMIT 5;
--     3a. First, write a query that finds the top 5 prescribers in
-- Nashville in terms of the total number of claims (total_claim_count)
-- across all drugs. Report the npi, the total number of claims, 
-- and include a column showing the city.
-- 1538103692	"FUROSEMIDE"	2122	"NASHVILLE"
-- 1538103692	"AMLODIPINE BESYLATE"	1911	"NASHVILLE"
-- 1407182157	"PREDNISOLONE ACETATE"	1714	"NASHVILLE"
-- 1538103692	"GABAPENTIN"	1645	"NASHVILLE"
-- 1952392797	"HYDROCODONE-ACETAMINOPHEN"	1578	"NASHVILLE"
SELECT npi,drug_name, total_claim_count, nppes_provider_city
FROM prescription
INNER JOIN prescriber
USING(npi)
WHERE nppes_provider_city ILIKE '%Nashville%'
ORDER BY total_claim_count DESC
LIMIT 5;
--     b. Now, report the same for Memphis.
-- 1225056872	"AMLODIPINE BESYLATE"	2956	"MEMPHIS"
-- 1639399769	"METHOTREXATE"	2878	"MEMPHIS"
-- 1346291432	"AMLODIPINE BESYLATE"	2859	"MEMPHIS"
-- 1346291432	"FUROSEMIDE"	2849	"MEMPHIS"
-- 1639399769	"PREDNISONE"	2598	"MEMPHIS"
SELECT npi,drug_name, total_claim_count, nppes_provider_city
FROM prescription
INNER JOIN prescriber
USING(npi)
WHERE nppes_provider_city ILIKE '%Memphis%'
ORDER BY total_claim_count DESC
LIMIT 5;
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT npi,drug_name, total_claim_count, nppes_provider_city
FROM prescription
INNER JOIN prescriber
USING(npi)
WHERE nppes_provider_city IN
			(SELECT nppes_provider_city
			FROM prescriber
			WHERE nppes_provider_city ILIKE '%Nashville%'
				OR nppes_provider_city ILIKE '%Memphis%'
				OR nppes_provider_city ILIKE '%Knoxville%'
				OR nppes_provider_city ILIKE '%Chattanooga%')
ORDER BY total_claim_count DESC;

-- 4. Find all counties which had an above-average number of overdose deaths. 
-- Report the county name and number of overdose deaths.
SELECT fc.county, od.overdose_deaths
FROM  fips_county AS fc 
INNER JOIN overdose_deaths AS od
ON fc.fipscounty::INT = od.fipscounty
WHERE CAST(od.overdose_deaths AS INT) > (SELECT AVG(CAST(overdose_deaths AS INT))
											FROM overdose_deaths);
	
--5a. Write a query that finds the total population of Tennessee.
-- ANS: Population total: "TN"	11295400926
SELECT pb.nppes_provider_state,SUM(population)
FROM population AS p
	JOIN zip_fips AS zp
	USING(fipscounty)
		JOIN prescriber AS pb
		ON(zp.zip = pb.nppes_provider_zip5)
WHERE nppes_provider_state ILIKE '%TN%'
GROUP BY nppes_provider_state;

--5b. Build off of the query that you wrote in part a to write a query that
-- returns for each county that county's name, its population, and the
-- percentage of the total population of Tennessee 
-- that is contained in that county.

WITH total_tn_pop AS(SELECT SUM(population) AS sum_pop_tn --county
							FROM population AS p
								JOIN zip_fips AS zf
								USING(fipscounty)
									JOIN prescriber AS pb
									ON (zf.zip= pb.nppes_provider_zip5)
							WHERE nppes_provider_state = 'TN')
SELECT fc.county, SUM(population) AS total_pop, ((SELECT sum_pop_tn FROM total_tn_pop)/SUM(population)*100) AS percernt_pop_tn
FROM fips_county AS fc
	INNER JOIN population AS p
	USING(fipscounty)
		JOIN zip_fips AS zf
		USING(fipscounty)
			JOIN prescriber AS pb
			ON (zf.zip= pb.nppes_provider_zip5)
GROUP BY fc.county;






