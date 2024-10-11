DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS lawyer CASCADE;
DROP TABLE IF EXISTS cases CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS billing CASCADE;
DROP TABLE IF EXISTS onCase CASCADE;

--1
CREATE TABLE client (
    cname VARCHAR(20), 
    address VARCHAR(50), 
    phone CHAR(11), 
    email VARCHAR(50), 
    PRIMARY KEY (cname)
);

CREATE TABLE lawyer (
    lname VARCHAR(20), 
    specialization VARCHAR(20), 
    ophone CHAR(11), 
    email VARCHAR(50), 
    office INT, 
    hbilling INT, 
    partner DATE DEFAULT NULL,
    PRIMARY KEY (lname)
);

CREATE TABLE cases (
    cid INT, 
    title VARCHAR(20), 
    description VARCHAR(150), 
    status DATE DEFAULT NULL, 
    lname VARCHAR(20), 
    cname VARCHAR(20),
    PRIMARY KEY (cid),
	FOREIGN KEY (lname) REFERENCES lawyer,
    FOREIGN KEY (cname) REFERENCES client
);

CREATE TABLE documents (
    cid INT, 
    dname VARCHAR(20), 
    dtype VARCHAR(20),
    PRIMARY KEY (cid, dname),
	FOREIGN KEY (cid) REFERENCES cases
);

CREATE TABLE billing (
    bdate DATE, 
    lname VARCHAR(20), 
    cid INT, 
    hours INT, 
    description VARCHAR(150), 
    amount INT,
    PRIMARY KEY (bdate, lname),
	FOREIGN KEY (lname) REFERENCES lawyer,
    FOREIGN KEY (cid) REFERENCES cases
);

CREATE TABLE onCase (
    cid INT, 
    lname VARCHAR(20), 
    role VARCHAR(20),
    PRIMARY KEY (cid, lname),
	FOREIGN KEY (cid) REFERENCES cases,
    FOREIGN KEY (lname) REFERENCES lawyer
);

--2
CREATE OR REPLACE FUNCTION trigf1()
RETURNS TRIGGER AS $$
BEGIN
    NEW.amount := (
        SELECT hbilling * NEW.hours
        FROM lawyer
        WHERE lawyer.lname = NEW.lname
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER T1
BEFORE INSERT OR UPDATE ON billing
FOR EACH ROW
EXECUTE FUNCTION trigf1();

--3
INSERT INTO client (cname, address, phone, email) VALUES
    ('Eric', '123 Main St', '5551111', 'eric@client.com'),
    ('Emily', '456 Oak Rd', '5552222', 'emily@client.com'),
    ('Robert', '789 Elm St', '5556789', 'robert@client.com'),
    ('Amy', '654 Pine Ave', '5555555', 'amy@client.com');

INSERT INTO lawyer (lname, specialization, ophone, email, office, hbilling, partner) VALUES
    ('Jessica', 'Environmental', 5550123, 'jessica@lawfirm.com', 1, 750, '2020-05-10'),
    ('Sarah', 'Employment', 5552345, 'sarah@lawfirm.com', 5, 150, NULL),
    ('David', 'Family', 5555555, 'david@lawfirm.com', 12, 200, NULL);

INSERT INTO cases (cid, title, description, status, lname, cname) VALUES
    (1, 'Eric vs. All', 'Civil dispute over contract', NULL, 'Sarah', 'Eric'),
    (2, 'Divorce', 'Family law case of divorce', NULL, 'David', 'Robert'),
    (3, 'Marriage', 'Contract before marriage', NULL, 'David', 'Eric'),
    (4, 'Emily Child Custody', 'Case of child custody', NULL, 'David', 'Emily'),
    (5, 'Emily vs. Plastic', 'Environmental case', NULL, 'Jessica', 'Emily'),
    (6, 'Amy vs. Gas', 'Environmental case', NULL, 'Jessica', 'Amy'),
    (7, 'Eric New Job', 'Contract for new job', NULL, 'Sarah', 'Eric'),
    (8, 'Emily vs. NASA', 'Environmental case', NULL, 'Jessica', 'Emily');

INSERT INTO documents (cid, dname, dtype) VALUES
	(1, 'doc1.pdf', 'legal document'),
	(1, 'doc2.docx', 'legal document'),
	(2, 'doc1.ppt', 'legal document');

INSERT INTO billing (bdate, lname, cid, hours, description, amount) VALUES
    ('2024-07-25', 'Jessica', 5, 3, 'Something', 0),
    ('2024-07-27', 'Jessica', 5, 3, 'Something important', 0),
    ('2024-07-26', 'Sarah', 5, 4, 'Something else', 0),
    ('2024-08-01', 'Sarah', 1, 2, 'Court appearance', 0),
    ('2024-07-20', 'Sarah', 1, 6, 'Court appearance', 0),
    ('2024-08-02', 'David', 2, 2, 'Something', 0),
    ('2024-07-30', 'David', 2, 5, 'Client meeting', 0),
    ('2024-07-31', 'Jessica', 2, 3, 'Court appearance', 0);

INSERT INTO onCase (cid, lname, role) VALUES
    (5, 'Sarah', 'Associate'),
    (5, 'David', 'Associate'),
    (2, 'Jessica', 'Associate');

--4
SELECT c.cid, c.title, l.lname, l.specialization
FROM cases c
JOIN lawyer l ON c.lname = l.lname
WHERE c.status IS NULL;

--5
SELECT c.cname
FROM cases c
GROUP BY c.cname
HAVING COUNT(c.cid) = 1
AND MAX(c.cid) NOT IN (SELECT cid FROM onCase);

--6
SELECT c.cname, MIN(c.cid) AS cid1, MAX(c.cid) AS cid2
FROM cases c
JOIN lawyer l ON c.lname = l.lname
WHERE c.status IS NULL
  AND l.partner IS NOT NULL
GROUP BY c.cname, l.lname
HAVING COUNT(c.cid) >= 2;

--7
SELECT b.lname, b.cid, SUM(b.amount) AS total_payment
FROM billing b
WHERE 
    date_part('year', b.bdate) = date_part('year', CURRENT_DATE)
    AND date_part('month', b.bdate) = date_part('month', CURRENT_DATE)
GROUP BY b.lname, b.cid;

--8
SELECT b.lname
FROM billing b
GROUP BY b.lname
HAVING SUM(b.hours) > 7
  AND COUNT(DISTINCT b.cid) > (
      SELECT COUNT(DISTINCT cid)
      FROM cases
      WHERE lname = 'Jessica'
  );

--9
WITH lawyer_counts AS (
    SELECT c.cid, COUNT(DISTINCT oc.lname) + 1 AS lawyer_count
    FROM cases AS c
    JOIN lawyer AS l1 ON c.lname = l1.lname
    LEFT JOIN onCase AS oc ON c.cid = oc.cid
    LEFT JOIN lawyer AS l2 ON oc.lname = l2.lname
    WHERE c.status IS NULL 
      AND l1.partner IS NULL
      AND (l2.partner IS NULL OR l2.lname IS NULL)
    GROUP BY c.cid
),
max_lawyer_count AS (
    SELECT MAX(lawyer_count) AS max_count
    FROM lawyer_counts
)
SELECT lc.cid, lc.lawyer_count
FROM lawyer_counts AS lc
JOIN max_lawyer_count AS mlc ON lc.lawyer_count = mlc.max_count;

--10
SELECT l.lname
FROM lawyer l
JOIN (
    SELECT lname
    FROM cases
    GROUP BY lname
    HAVING COUNT(cid) = 1
) lwc ON l.lname = lwc.lname
JOIN (
    SELECT oc.lname
    FROM onCase oc
    GROUP BY oc.lname
    HAVING COUNT(DISTINCT oc.cid) >= (SELECT COUNT(*) FROM cases) - 1
) lhc ON l.lname = lhc.lname
WHERE l.partner IS NULL;


