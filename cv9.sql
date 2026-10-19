-- 1. oracle directory read write 2. v bloku prikazov najprv ziskam adresu smernik na externy subor (funkcia bfile name) 4. ziskam temporalny blob a pomocou insert alebo update urobim z neho interny lob
--ako zistim ake indexy su nad tabulkou student 
select index_name, table_name from user_indexes
    where table_name = 'STUDENT';
    
    select constraint_name, constraint_type
    from user_constraints
    where table_name = 'STUDENT'
    and constraint_type = 'P'; --constraint primarny kluc
    
select os_cislo, dat_zapisu, rod_cislo -- keby chcem este vhodnejsi index tak by obsahoval vsetko toto
    from student
        where os_cislo = 501512; -- index unique scan
        ----------
select os_cislo, dat_zapisu, rod_cislo -- keby chcem este vhodnejsi index tak by obsahoval vsetko toto
    from student
        where rod_cislo = '841106/3456';
        
create index ind1 on student(rod_cislo); -- k predchadzajucemu sa spusti index range scan (nie je unikatny), ostatne sa ziskaju pomocou rowid

select os_cislo, dat_zapisu, rod_cislo -- keby chcem este vhodnejsi index tak by obsahoval vsetko toto
    from student
        where  dat_zapisu = to_date('01.09.2023', 'DD.MM.YYYY');

create index ind2 on student(dat_zapisu, os_cislo, rod_cislo); --najvhodnejsi index

select os_cislo, dat_zapisu, rod_cislo -- keby chcem este vhodnejsi index tak by obsahoval vsetko toto
    from student
        where  to_char(dat_zapisu, 'YYYY') = 2007; -- table access full lebo sa porovnava rok mocou funkcie, nie rovno dat_zapisu
-- fast full vyuziva zoradovanie dat
create index ind2 on student(to_char(dat_zapisu, 'YYYY'), dat_zapisu, os_cislo, rod_cislo); --musim to dat dva krat, lebo sa pouziva aj cisto to dat_zapisu,
                                                                                            --ale aj tak sa pouziva index full scan lebo nema vhodne poradie atributov
                                                                                            --lebo v tom selecte porovnavam retazec s cislom to_char(dat_zapisu, 'YYYY') = 2007
                                                                                            --ak chcem index range scan tak zmenim na '2007' (pridam uvodzovky), treba mysliet na implicitne konverzie
                                                                                            -- keby chcem iba number tak musim dat to_number aj do selectu aj do inexu 
                                                                                        
--spajanie tabuliek -- su zoradene podla primarneho kluca 
--nested loop tabulka nad cudzim klucom je nahodne hodne, v cykle prehladavam tabulku s cudzim klucom O(n * lon(m))), pouziva sa ked nad cudzim klucom nemam index
--merge join ked nad cudzim klucom mam index, aj podla primarneho kluca aj podla cudieho je zoradene, iteruje sa dokym sa nenajde vacia hodnota
--hash match -- rodelemi si ju na mensie casti a prehladavaju sa sekvencne cele tie mensie casti
--ak nemam nad fk index a ak je tabulka mala tak nested loop a ak je velka tak hash match
-- databaze sa rozhodne ktoru pouzije podla dbms_stats poctu dat
--adaptive join zistuje ci su statistiky aktualne a ak nie tak sa prepne metoda
--dbms_stats_gather_table_stats

select rod_cislo, meno, priezvisko , os_cislo, rocnik from os_udaje join student using (rod_cislo);
 -- naemame index nad cudzim klucom tak merge vypadne, ked je malo dat tak sa pouzije nested loop by som si myslel ale pouzije sa merge join
 -- ale vytvoril sa sam od seba sort (co je index) -- vytvoril sa dynamicky index
 
 select /*+Use_NL(os_udaje student) */ rod_cislo, meno, priezvisko , os_cislo, rocnik from os_udaje join student using (rod_cislo); -- hint na pouzitie vybranej metody
  select /*+Use_NL(os_udaje student) */ rod_cislo, meno, priezvisko , os_cislo, rocnik from os_udaje join student using (rod_cislo); -- hint na pouzitie vybranej metody
  select * from kvet3.osoba_tab;
  create table osoba_tab (rod_cislo char(11) not null, meno varchar(30), priezvisko varchar(30)
  );
  insert into osoba_tab (select * from kvet3.osoba_tab);
  drop table osoba_tab;
  
SELECT 
    state, RANK() OVER (PARTITION BY State ORDER BY Age DESC) AS AgeRankByState
FROM road_deaths;