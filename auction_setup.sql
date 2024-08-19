-- TABLES
create table products( productId number primary key , productName varchar(30) , 
    description varchar(40) , starting_price number(30) );

create table users( userId number primary key ,  firstName varchar(20) , 
    lastName varchar(20) , address varchar(100));

create table contact_numbers( userId number , phone_no number , 
    foreign key (userId) references users(userId) , primary key (userId , phone_no))

create table bids( bidId number primary key, bid_amount number(30) , bidding_time timestamp , 
    userId number , productId number , foreign key (userId) references users(userId) , 
    foreign key (productId) references products(productId));

create table results( productId number primary key , userId number , bidId number , 
    final_amount number(30) , bidding_time timestamp , no_of_bids number , 
    foreign key (productId) references products(productId) , foreign key (userId) references users(userId) ,
    foreign key (bidId) references bids(bidId));

create table payments( userId number primary key , total_amount number(30) , user_bids_count number , 
    foreign key (userId) references users(userId));




-- USERS & PRODUCTS - Values
insert into products values( 101 , 'Duke 390' , 'Dyno Tested 43.6 hp , Odometer 4740 Km' ,  250000 );
insert into products values( 102 , 'Yamaha R6' , 'Dyno Tested 117 hp , Odometer 2000 Km' , 1250000);
insert into products values( 103 , 'BMW S1000 RR' , 'Dyno Tested 209 hp , Odometer 3000 Km', 2180000 );
insert into products values( 104 , 'Ducati Panigale V4R' , 'Dyno Tested 227 hp , Odometer 1700 Km' , 4490000);
insert into products values( 105 , 'Kawasaki Ninja 400' , 'Dyno Tested 44.2 hp , Odometer 1100 Km' , 410000);
insert into products values( 106 , 'Super Splendor' , 'Dyno Tested 6.9 hp , Odometer 10800 Km', 20000);
insert into products values( 107 , 'Ducati Superleggera V4R' , 'Dyno Tested 231 hp , Odometer 860 Km' , 12000000);




insert into users values( 1 , 'Giriraj' , 'Dhyani' , 'B104 , Hostel C , Thapar , Patiala , Punjab');
insert into users values( 2 , 'Parth' , 'Kapoor' , 'E206 , Hostel C , Thapar , Patiala , Punjab');
insert into users values( 3 , 'Gouri' , 'Rabgotra' , 'L , Hostel L , Thapar , Patiala , Punjab');
insert into users values( 4 , 'Anisha' , 'Sharma' , 'L , Hostel L , Thapar , Patiala , Punjab');
insert into users values( 5 , 'Shishimaru', 'Kumar' , 'C116 , Hostel C , Thapar , Patiala , Punjab');
insert into users values( 6 , 'Deepok' , 'Kalal', 'D335 , Hostel B , Thapar , Patiala , Punjab');
insert into users values( 7 , 'Ramneek' , 'Sharma', 'C109 , Hostel C , Thapar , Patiala , Punjab');
insert into users values( 8 , 'Aarya' , 'Underage' , 'B104 , Hostel C , Thapar , Patiala , Punjab');

insert into contact_numbers values(1 , 6395696432);
insert into contact_numbers values(1 , 9456032926);
insert into contact_numbers values(2 , 7009822678);
insert into contact_numbers values(2 , 9815529664);
insert into contact_numbers values(3 , 8979374457);
insert into contact_numbers values(3 , 6280167251);
insert into contact_numbers values(4 , 6283760168);



-- PROCEDURES


-- Procedure to print user Info
create or replace procedure printUserInfo(uId in number) as
    userDetails users%rowtype;
	cursor c1 is select * from contact_numbers where userId = uId;
begin
	select * into userDetails from users where userId = uId;
	dbms_output.put_line('User Name : ' || userDetails.firstName || ' ' || userDetails.lastName);
	dbms_output.put_line('User Id : ' || userDetails.userId);
	dbms_output.put_line('User Address : ' || userDetails.address);

	for r in c1 loop
        dbms_output.put_line('User Contact Number: ' || r.phone_no);
	end loop;
end;
/



-- procedure to Add New Bids & update them in results table
CREATE OR REPLACE PROCEDURE addBids( amt IN NUMBER, u_id IN NUMBER, p_id IN NUMBER ) AS
    prevResultBid results%ROWTYPE;
	productDetails products%rowtype;
	totalBidsCount number;
    currentTime TIMESTAMP;
	bidExists boolean;
	validTime boolean;
	b_id number;
	cursor c1 is select * from results;
BEGIN
    SELECT TO_TIMESTAMP(TO_CHAR(SYSDATE, 'HH24:MI:SS'), 'HH24:MI:SS') INTO currentTime FROM dual;
	select count(*) into totalBidsCount from bids;
	b_id := 1001 + totalBidsCount;

    INSERT INTO bids VALUES ( b_id, amt, currentTime, u_id, p_id);
	dbms_output.put_line('New Bid Added!');

	bidExists := false;

	for rec in c1 loop
        if rec.productId = p_id then
			bidExists := true;		
		end if;
	end loop;

	if bidExists then
        dbms_output.put_line('exists');
		select * into prevResultBid from results where productId = p_id;
		checkTime(prevResultBid.bidding_time , currentTime , validTime);
		
		if validTime then
			update results set userId = u_id , bidId = b_id , final_amount = amt , bidding_time = currentTime , 
                no_of_bids = prevResultBid.no_of_bids + 1 where productId = prevResultBid.productId;
			dbms_output.put_line('Successfuly Updated Results! Add New bid in next 30s');
        else 
        	dbms_output.put_line('Bid not updated!');
		end if;
	else
        dbms_output.put_line('doesnot exists');
		select * into productDetails from products where productId = p_id;
		if amt < productDetails.starting_price then
			dbms_output.put_line('Less than Starting Price of ' || productDetails.starting_price);
        	dbms_output.put_line('Bid not updated!');
        else
            dbms_output.put_line(b_id);
			insert into results values( p_id , u_id , b_id , amt , currentTime , 1);
			dbms_output.put_line('Successfuly Updated Results! Add New bid in next 30s');
		end if;
	end if;
end;
/


    
-- Procedure to check valid time
CREATE OR REPLACE PROCEDURE checkTime(
    p_bidTime IN TIMESTAMP,
    p_system_time IN TIMESTAMP,
    validTime OUT BOOLEAN
) AS
    curr_time TIMESTAMP;
    sys_time TIMESTAMP;
    time_difference INTERVAL DAY TO SECOND;
    total_seconds NUMBER;
BEGIN
    SELECT TO_TIMESTAMP(TO_CHAR(p_bidTime, 'HH24:MI:SS'), 'HH24:MI:SS') INTO curr_time FROM dual;
    SELECT TO_TIMESTAMP(TO_CHAR(p_system_time, 'HH24:MI:SS'), 'HH24:MI:SS') INTO sys_time FROM dual;
    
    time_difference := sys_time - curr_time;
    
    total_seconds := EXTRACT(DAY FROM time_difference) * 86400 +
                     EXTRACT(HOUR FROM time_difference) * 3600 +
                     EXTRACT(MINUTE FROM time_difference) * 60 +
                     EXTRACT(SECOND FROM time_difference);
    
    IF (total_seconds < 30) THEN
        DBMS_OUTPUT.PUT_LINE('Valid Time , time difference of ' || total_seconds || ' s');
        validTime := TRUE;
    ELSE
        DBMS_OUTPUT.PUT_LINE('INVALID Time , time difference of ' || total_seconds || ' s');
        validTime := FALSE;
    END IF;
END;
/




-- Procedure to Update Payments
create or replace procedure updatePayments as
    cursor c1 is select * from users;
	cursor c2 is select * from results;
	prevUserPayment payments%rowtype;
begin
    delete from payments;
    for r1 in c1 loop
		insert into payments values(r1.userId , 0 , 0 );
    end loop;

	for r2 in c2 loop
		select * into prevUserPayment from payments where userId = r2.userId;
        update payments set total_amount = prevUserPayment.total_amount + r2.final_amount , 
            user_bids_count = prevUserPayment.user_bids_count + 1 where userId = r2.userId;
    end loop;

end;
/

-- Procedure to Give total Amount of any User
create or replace procedure createBill( uId in number) as
    itemDetails payments%rowtype;
	userDetails users%rowtype;
	productDetails products%rowtype;
	cursor resultsCursor is select * from results where userId = uId;
    begin
    	updatePayments();
		select * into itemDetails from payments where userId = uId;
		select * into userDetails from users where userId = uId;
		dbms_output.put_line('EzzHawk Auction Bill');
		printUserInfo(uId);

		for r in resultsCursor loop
            select * into productDetails from products where productId = r.productId;
			dbms_output.put_line(userDetails.firstName || ' just bought ' 
                || productDetails.productName || ' for ₹' || r.final_amount );
        end loop;
		
		dbms_output.put_line( 'Total Payment from User : ₹' ||
            itemDetails.total_amount );
		dbms_output.put_line( 'Total Successful Bids from User : ' || 
            itemDetails.user_bids_count );
	end;
	/



-- Procedure to Get Results of Each User
create or replace procedure userResults( uid in number ) as
	cursor c1 is select * from results where userId = uid;
begin
    printUserInfo(uid);
    for r in c1 loop
		dbms_output.put_line('Bid Id : ' || r.bidId);
		dbms_output.put_line('Product Id : ' || r.productId);
		dbms_output.put_line('Bidding Amount : ' || r.final_amount);
		dbms_output.put_line('No. of Bids for this Product : ' || r.no_of_bids);
    end loop;
end;
/

