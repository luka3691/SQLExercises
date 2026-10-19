-- zagregovat vnucata
create table rodokmen
(id integer primary key, 
 meno varchar(50), 
 priezvisko varchar(50), 
 id_matky integer, 
 id_otca integer, 
 foreign key(id_matky) references rodokmen(id),
 foreign key(id_otca) references rodokmen(id)
); 
insert into rodokmen values(1, 'Peter', 'Marko', null, null);
insert into rodokmen values(2, 'Jana', 'Ozová', null, null);
insert into rodokmen values(3, 'Miroslava', 'Marková', 1,2);
insert into rodokmen values(4, 'Peter', 'Marko', 1,2);
insert into rodokmen values(5, 'Juraj', 'Marko', 1,2);
insert into rodokmen values(6, 'Stanislava', 'Marková', 1,2);
insert into rodokmen values(7, 'Daniela', 'Draškovièová', null,null);
insert into rodokmen values(8, 'Melánia', 'Marková', 7,4);
insert into rodokmen values(9, 'Jozefína', 'Marková', 7,4);
insert into rodokmen values(10, 'Vlasta', 'Marková', 7,4);
insert into rodokmen values(11, 'Stanislav', 'Šedivý', null, null);
insert into rodokmen values(12, 'Karol', 'Šedivý', 6, 11);
insert into rodokmen values(13, 'Karolína', 'Šedivá', 6, 11);
insert into rodokmen values(14, 'Marek', 'Šedivý', 6, 11);
insert into rodokmen values(15, 'Tomáš', 'Šedivý', 6, 11);
insert into rodokmen values(16, 'Emil', 'Káèer', null, null);
insert into rodokmen values(17, 'Anna', 'Káèerová', 3, 17);
insert into rodokmen values(18, 'Mikuláš', 'Káèer', 3, 17);
insert into rodokmen values(19, 'Alexej', 'Káèer', 3, 17);
insert into rodokmen values(20, 'Jozef', 'Mak', 9, 20);
insert into rodokmen values(21, 'Terézia', 'Maková', 9, 20);
insert into rodokmen values(22, 'Ján', 'Maková', 9, 20);
insert into rodokmen values(23, 'Jana', 'Maková', 9, 20);
insert into rodokmen values(24, 'Ctibor', 'Bralo', null, null);
insert into rodokmen values(25, 'Jana', 'Bralová', 10, 24);
insert into rodokmen values(26, 'Ctibor', 'Bralo', 10, 24);
insert into rodokmen values(27, 'Martina', 'Moková', null, null);
insert into rodokmen values(28, 'Michal', 'Moko', 27, 20);
insert into rodokmen values(29, 'Marian', 'Moko', 27, 20);
commit;

select osoba.id, listagg(surodenec.meno || surodenec.priezvisko, ',')
    from rodokmen osoba join rodokmen surodenec using (id_matky)
        where osoba.id != surodenec.id
            group by osoba.id ;
select listagg('stary rodic' ) within group by(order by gp.meno, gc.meno) as parent
from rodokmen gp
join rodokmen p on (gp.id = p.id_matky or gp.id = p.id_otca)
join rodokmengc on (gp.id = gc.id_matky or gp.id = gc.id_otca)
group by gp.id;

--ku kazdej osobe vypisat studentske udaje meno, priezvisko a dat zapisu rocnik iba ak este studuje

select meno, priezvisko, dat_zapisu, rocnik
    from os_udaje
        left join student on (os_udaje.rod_cislo = student.rod_cislo and ukoncenie is null);


create directory filadelfi_blob_dir as '\C:\Bloby_student\filadelfi\';
    

create table blob.table 
(
id integer,
nazov varchar(20),
subor blob,
pripona varchar2(5)
);
/

declare
v_source_blob BFILE := BFILENAME('KVET_BLOB_DIR', 'PES.JPG');
v_size_blob integer;
v_blob BLOB := EMPTY_BLOB();
begin
DBMS_LOB.OPEN(v_source_blob, DBMS_LOB.LOB_READONLY);
v_size_blob := DBMS_LOB.GETLENGHT(v_source_blob);
insert into 
end;

--namapovat subor do databazy
--mam subor mimo databazy
--1. musim ulozit cestu k obrazku do databazy pomocou objektu directory
--xml meno, priezvisko (musi byt atribut), element prispevky (budu agregovane), element zamestnavatelia (zoznam zamestnavatelov), element odvody (pole odvodov)
--ulozit to cele do clobu
--potom spat z clobu to na xml a zmenit vsetky priezviska na Finalny
--select xmlelement ('meno', meno) -> getClobVal()
-- select subor -> musim zavolat konstruktor xml dokumentov xmltype(subor)
/

select xmlroot( xmlelement("osoba",xmlattributes(meno as meno, priezvisko as priezvisko))
        
        , version no version) from soc.poistovna.p_osoba;

select xmlroot(xmlelement("osoba",xmlattributes(rod_cislo as rod_cislo, meno as meno, priezvisko as priezvisko),
                                xmlagg(xmlelement("platba",xmlattributes(id_poberatela as id_poberatela)))
                        ),version no value) as xml 
                    from soc_poistovna.p_osoba join soc_poistovna.p_poberatel using (rod_cislo) left join soc_poistovna.p_prispevky using (id_poberatela) group by rod_cislo, meno, priezvisko, id_poberatela;

select xmlroot(xmlagg(xmlelement("osoba",xmlattributes(id_poberatela as id_poberatela), 
                                        xmlelement("vsetky platby", 
                                                xmlagg(xmlelement("platba",xml(suma as suma)))))),
                     version no value) as xml 
                    from soc_poistovna.p_osoba left join soc_poistovna.p_poberatel using (rod_cislo) left join soc_poistovna.p_prispevky using (id_poberatela) group by rod_cislo;  
                
          --          left join soc_poistovna.p_zamestnanec using (rod_cislo) group by rod_cislo ;
select rod_cislo from soc_poistovna.p_osoba join soc_poistovna.p_poberatel using (rod_cislo) join soc_poistovna.p_prispevky using (id_poberatela) 
                    join soc_poistovna.p_zamestnanec using (rod_cislo) group by rod_cislo