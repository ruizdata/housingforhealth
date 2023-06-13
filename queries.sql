-- HOUSING FOR HEALTH analytics engineering

Assumptions

1. Existing housing records are updated using Data Manipulation Language (DML). New records are added using Data Definition Language (DDL).
2. Erroneous records, including those null or redundant, can be replaced with correct records.

-- QUALITY ASSURANCE

   Client table, test 1

   Test that the primary key (PK) is unique and has an integrity constraint.

   If Error, then Pass.

INSERT INTO client_id
VALUES ( ‘Test’, 02/15/2023, ‘LADHS’ ), 
       ( ‘Test’, 02/15/2023, ‘LADHS’ );

-- Client table, test 2

   Test columns for correct data type, especially dates for later calculations.

   If application dates are formatted MM/DD/YYYY, then Pass.

SELECT column, 
       data_type
FROM information_schema.columns
WHERE table_name = ‘client’ and table_schema = ‘schema_name’;

-- Housing Episode table, test 1
 
   Test for housing episodes with null values, meaning missing either client or property.

   If No Results, then Pass.

SELECT housing_event_id
FROM housing_episode
WHERE client_id OR property_id IS NULL;

-- Housing Episode table, test 2	

   Test for illogical housing timelines, such as move-out date precedes move-in date (1st statement), or dates are outside known tenancy agreements (2nd statement).

   If No Results, then Pass.

SELECT housing_event_id
FROM housing episode
WHERE move_out_date <= move_in_date;

SELECT housing_event_id
FROM housing episode
WHERE move_in_date <  01/01/2022 OR move_out_date > 12/31/2025;

-- Property table, test 1:
	
   Test that all properties are in California.

   If No Results, then Pass.

SELECT property_id
FROM property
WHERE state != ‘California’;

-- Property table, test 2:

   Test columns for correct data type, this time for referential integrity. Data type and domain must match between primary key and foreign key (FK) for joins to work.

   If identification numbers are formatted varchar(255), then Pass.

SELECT column, 
       data_type
FROM information_schema.columns
WHERE table_name = ‘property’ and table_schema = ‘schema_name’;

-- KEY PERFORMANCE INDICATORS

Before calculation, produce a common table expression (CTE) relating all three tables. Due to the limited number of tables, this preparatory CTE preserves query performance. 

WITH housing_comb AS 
(	
SELECT housing_episode.*,
       client.*, 
       property.* 
FROM housing_episode
JOIN client 
ON housing_episode.client_id = client.client_id
JOIN property
ON housing_episode.property_id = property.property_id	
);

-- Indicator 1 

Select the number of clients who have not yet moved in.

SELECT COUNT(client_id)
FROM housing_comb
WHERE move_in_date IS NULL;

-- Indicator 2 

Select the average number of days from a client's application date and the first move-in date.

ALTER TABLE housing_comb
ADD move_in_speed INT

UPDATE move_in_speed
SET move_in_speed = move_in_date – application_date		-- Move-in speed formula

SELECT AVG(move_in_speed)
FROM housing_comb;

-- Indicator 3

Based on the average number of days from client's application date and first move-in date, select how many programs are housing clients faster than the average.

SELECT COUNT(DISTINCT program_name)	
FROM housing_comb
WHERE move_in_speed < AVG(move_in_speed);

-- Indicator 4

Select the number of clients who have been relocated (has more than 1 housing episode).

SELECT COUNT(housing_event_id) AS relocated
FROM housing_comb
GROUP BY housing_event_id
HAVING COUNT(housing_event_id) > 1;

-- Indicator 5

Select which five (5) zip codes have the highest average relocation rates (Number of Clients relocated from a property in a given zip code DIVIDED BY Number of Clients housed in a property in that zip code)?

SELECT COUNT(housing_event_id) AS occupied
FROM housing_comb
GROUP BY housing_event_id
HAVING COUNT (housing_event_id) = 1	

ALTER TABLE housing_comb
ADD relocate_rate INT

UPDATE housing_comb
SET relocate_rate = relocated / occupied			-- Relocation rate formula

SELECT zip, 
       relocate_rate
FROM housing_comb
GROUP by zip
ORDER by relocate_rate DESC
LIMIT 5;

-- Indicator 6

Select the overall average occupancy rate (Number of Clients in Property DIVIDED BY Number of Units in Property) of properties by region and program.

SELECT SUM(number_of_units) AS total_units
FROM housing_comb

ALTER TABLE housing_comb
ADD occup_rate INT

UPDATE housing_comb
SET occup_rate = occupied / total_units			         -- Occupancy rate formula

SELECT AVG(occup_rate)
FROM housing_comb
GROUP BY by region, program_name;
