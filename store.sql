CREATE TABLE CUSTOMER
(
    CID CHAR(9) NOT NULL,
    First VARCHAR(20) NOT NULL,
    Last VARCHAR(20) NOT NULL,
    State CHAR(2),
    City VARCHAR(20),
    ZIP CHAR(5),
    Street VARCHAR(25),
    PRIMARY KEY (CID)
);

-- ENUM for PAYMENT_METHODS.PaymentType
CREATE TYPE payment AS ENUM('credit', 'paypal');

CREATE TABLE PAYMENT_METHODS
(
    CID CHAR(9) NOT NULL,
    Nickname VARCHAR(20) NOT NULL,
    PaymentType payment NOT NULL,
    PRIMARY KEY (CID, Nickname),
    FOREIGN KEY (CID) REFERENCES CUSTOMER(CID)
);

CREATE TABLE MERCHANDISE
(
    MID CHAR(9) NOT NULL,
    PRIMARY KEY (MID)
);

CREATE TABLE BUYS
(
    CID CHAR(9) NOT NULL,
    MID CHAR(9) NOT NULL,
    Quantity INT,   -- add a trigger to make sure Quantity >= 0
    PRIMARY KEY (CID, MID),
    FOREIGN KEY (CID) REFERENCES CUSTOMER(CID),
    FOREIGN KEY (MID) REFERENCES MERCHANDISE(MID)
);

-- ENUMs for table VIDEO_GAME
CREATE TYPE rating AS ENUM('E', 'T', 'M');
CREATE TYPE platform AS ENUM('Playstation', 'Xbox', 'Nintendo', 'PC');

CREATE TABLE VIDEO_GAME
(
    UPC CHAR(12) NOT NULL,
    MID CHAR(9),
    Rating rating NOT NULL,
    Platform platform NOT NULL,
    PRIMARY KEY (UPC),
    FOREIGN KEY (MID) REFERENCES MERCHANDISE(MID)
);

CREATE TABLE BOOKS
(
    ISBN CHAR(13) NOT NULL,
    MID CHAR(9),
    Genre VARCHAR(20),
    PRIMARY KEY (ISBN),
    FOREIGN KEY (MID) REFERENCES MERCHANDISE(MID)
);

CREATE TABLE AUTHORS
(
    ISBN CHAR(13) NOT NULL,
    Author VARCHAR(20) NOT NULL,
    PRIMARY KEY (ISBN, Author),
    FOREIGN KEY (ISBN) REFERENCES BOOKS(ISBN)
);

CREATE TABLE COMICS
(
    ISBN CHAR(13) NOT NULL,
    Artist VARCHAR(20),
    PRIMARY KEY (ISBN),
    FOREIGN KEY (ISBN) REFERENCES BOOKS(ISBN)
);

CREATE TABLE STORE
(
    License VARCHAR(20) NOT NULL,
    Name VARCHAR(20),
    Phone CHAR(11),
    State CHAR(2),
    City VARCHAR(20),
    ZIP CHAR(5),
    Street VARCHAR(25),
    PRIMARY KEY (License)
);

CREATE TABLE HAS
(
    License VARCHAR(20) NOT NULL,
    MID CHAR(9) NOT NULL,
    Quantity INT,   -- make a trigger to check that Quantity >= 0
    PRIMARY KEY (License, MID),
    FOREIGN KEY (License) REFERENCES STORE,
    FOREIGN KEY (MID) REFERENCES MERCHANDISE(MID)
);

-- This trigger will check for Customer's address info
CREATE OR REPLACE FUNCTION check_customer_address()
RETURNS TRIGGER AS $check_customer_address$
    BEGIN
        IF (NEW.state IS NULL) OR (NEW.city IS NULL) OR (NEW.zip IS NULL) OR (NEW.street IS NULL) THEN
        RAISE EXCEPTION 'Enter a valid address.';
        END IF;
        RETURN NEW;
    END;
    $check_customer_address$ LANGUAGE plpgsql;

CREATE TRIGGER check_customer_address
    BEFORE INSERT ON CUSTOMER
    FOR EACH ROW
    EXECUTE PROCEDURE check_customer_address();

-- This trigger will check for the Store's info
CREATE OR REPLACE FUNCTION check_store_info()
RETURNS TRIGGER AS $check_store_info$
    BEGIN
        IF (NEW.Name IS NULL) OR (NEW.Phone IS NULL) OR  (NEW.State IS NULL) OR (NEW.City IS NULL) OR (NEW.ZIP IS NULL)
            OR (NEW.Street IS NULL) THEN
        RAISE EXCEPTION 'Stores need a name and a valid address.';
        END IF;
        RETURN NEW;
    END;
    $check_store_info$ LANGUAGE plpgsql;

CREATE TRIGGER check_store_info
    BEFORE INSERT ON STORE
    FOR EACH ROW
    EXECUTE PROCEDURE check_store_info();

--This trigger will make sure that quantity is of merchandise bought is greater than 0.
CREATE OR REPLACE FUNCTION check_quantity_buys()
RETURNS TRIGGER AS $check_quantity_buys$
    BEGIN
        IF NEW.Quantity =< 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than 0.';
        END IF;
        RETURN NEW;
    END;
    $check_quantity_buys$ LANGUAGE plpgsql;

CREATE TRIGGER check_quantity_buys
    BEFORE INSERT ON BUYS
    FOR EACH ROW
    EXECUTE PROCEDURE check_quantity_buys();

-- This trigger will check if the comic has an artist
CREATE OR REPLACE FUNCTION comic_has_artist()
RETURNS TRIGGER AS $check_comic_artist$
    BEGIN
        IF NEW.Artist IS NULL THEN
            RAISE EXCEPTION 'Comic needs an artist';
        END IF;
        RETURN NEW;
    END;
    $check_comic_artist$ LANGUAGE plpgsql;

CREATE TRIGGER comic_has_artist
    BEFORE INSERT ON COMICS
    FOR EACH ROW
    EXECUTE PROCEDURE comic_has_artist();

-- This trigger checks to see if store has a quantity of at least 0
CREATE OR REPLACE FUNCTION store_has_quantity()
RETURNS TRIGGER AS $store_has_quantity$
    BEGIN
        IF NEW.Quantity < 0 THEN
            RAISE EXCEPTION 'Store must have at least 0 items';
        END IF;
        RETURN NEW;
    END;
$store_has_quantity$ LANGUAGE plpgsql;

CREATE TRIGGER store_has_quantity
    BEFORE INSERT ON HAS
    FOR EACH ROW
    EXECUTE PROCEDURE store_has_quantity();

-- Stored procedure to update HAS.quantity whenever there's a new insert into BUYS
CREATE OR REPLACE PROCEDURE can_buy(IN value integer, IN m CHAR)
LANGUAGE SQL
AS $$
    UPDATE HAS
    SET quantity = quantity + value
    WHERE HAS.MID = m;
    $$;

-- Trigger that calls the stored procedure when inserting into BUYS
CREATE OR REPLACE FUNCTION update_has_quantity()
RETURNS TRIGGER AS $update_has_quantity$
    BEGIN
        CALL can_buy(NEW.Quantity, NEW.MID);
        RETURN NEW;
    end;
    $update_has_quantity$ LANGUAGE plpgsql;

CREATE TRIGGER update_has_quantity
    BEFORE INSERT ON BUYS
    FOR EACH ROW
    EXECUTE PROCEDURE update_has_quantity();

