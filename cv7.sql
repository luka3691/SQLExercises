create table idcka(
id number
);

begin
    for i in 1.. 20 loop
        insert into idcka values(i);
    end loop;
end;
/

select sum(id) over (order by id rows between 2 preceding and current row), id from idcka;