-- 1. Write a query which returns the total number of claims for these two groups.
-- SELECT total_claim_count, npi
-- FROM prescription
-- LIMIT 5;
SELECT pb.specialty_description, SUM(ps.total_claim_count) AS total_claims
FROM prescriber AS pb
INNER JOIN prescription AS ps
USING(npi)
WHERE pb.specialty_description LIKE '%Interventional Pain Management%' OR
		pb.specialty_description LIKE '%Pain Management%'
GROUP BY pb.specialty_description;
-- 2. Now, let's say that we want our output to 
-- also include the total number of claims between these two groups.
-- Combine 2 queries with the UNION keyword to accomplish this.
SELECT pb.specialty_description, SUM(ps.total_claim_count) AS total_claims
FROM prescriber AS pb
INNER JOIN prescription AS ps
USING(npi)
WHERE pb.specialty_description LIKE '%Interventional Pain Management%' OR
		pb.specialty_description LIKE '%Pain Management%'
GROUP BY pb.specialty_description
UNION ALL
SELECT 'Total' AS specialty_description, SUM(ps.total_claim_count) AS total_claims
FROM prescriber AS pb
INNER JOIN prescription AS ps
USING(npi)
WHERE pb.specialty_description LIKE '%Interventional Pain Management%' OR
		pb.specialty_description LIKE '%Pain Management%';

-- 3. Now, instead of using UNION, make use of GROUPING SETS
-- Write a query which returns the total number of claims for these two groups.
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description LIKE '%Interventional Pain Management%' OR
	specialty_description LIKE '%Pain Management%'
GROUP BY GROUPING SETS ((specialty_description), ());
-- 4. Modify your query (still making use of GROUPING SETS so that your 
-- output ALSO shows the total number of opioid claims vs. non-opioid claims 
-- by these two specialites: opioid_drug_flag Y and N
SELECT COUNT(d.opioid_drug_flag)AS opioid_claims,SUM(p.total_claim_count) AS total_claims
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
WHERE p.specialty_description LIKE '%Interventional Pain Management%' OR
	p.specialty_description LIKE '%Pain Management%'
GROUP BY GROUPING SETS ((p.specialty_description), (),
							d.opiod_drug_flag,());
