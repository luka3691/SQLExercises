--ked mam tabulku a ju zrusim, ona sa presunie do kosa v show recyclebin, realizovany formou premenovania tabulky, mozem obnovit pomcou create from (neobnovia sa indexy)
--mozem pouzit flashback a do isteho stavu sa vratit, LIFO

create table test_tab(id integer);
insert into test_tab values(1);

commit;
drop table test_tab;
flashback table test_tab to before drop; -- before


--drop table purge -- nie je obnovitelne
--vysypanie z kosa purge recyclebin;
--kos ma iba obmedzenu velkost, nie je casovo obmedzene

--logicky zurnal, pozostava z dvoch struktur, undo a redo
--v logickom zuranale mozem mat aj select -- 
--update student set rocnik = 2 where os = ...
--1. vyhlada sa rowid
--2. aplikuje sa exkluzivny  -- kovoli paralerizmu
--3. mozem vykonat update
--zapise sa do logov
--4.musim updatetovaù indexy tabulky
--5.commit (este stale je aplikovany zamok)
--select * from student
--postupne prechadzam, ale upravene data su este zamknute(cize by sa k nim nedalo pristupit), ale ako nahle k nim pristupim tak sa odomknu -- pretoto saukladaju aj select
-- chcem vratit tabulku do stavu pred hodinou
alter table student enable row movement; --musi byt povolene zmena rowid
flashback table student to timestamp(sysdate-1/24); -- nesmie menit strukturu, ale moze data --flashback table student to timestamp(systimestamp - interval '10' minute); 
--musim potom rebuildovat indexy
-- ked chem vidiet ako tabulka vyzerala pred 10 minut
select * from student as of timestamp(systimestamp - interval '10' minute);

--pristup k datam na vzdialenom servery (distibuovany select) - pristup k viacerym databazam naraz
--pomocou triggrov na databazou mozem dabranit zmenu hesla

--vytvorenie noveho pouzivatela
create database link dblinkxx  
connect to student05 
  identified by student05
   using '(DESCRIPTION =(ADDRESS = (PROTOCOL = TCP)
           (HOST = obelix.fri.uniza.sk)(PORT = 1522))
             (CONNECT_DATA =(SERVER = DEDICATED)
               (SERVICE_NAME = orcladm.fri.uniza.sk)  ) )'; --dedikovany = jeden klient ma jeden server proces
select * from test_tab@dblinkxx;
SELECT * FROM filadelfi.test_tab@dblinkxx;