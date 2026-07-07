
-- Esquema de la base de dades genealògica (branca Ramon d'Esparreguera)
drop table if exists families cascade;
drop table if exists persons cascade;

create table persons (
  id text primary key,
  given_name text,
  surname text,
  full_name text not null,
  sex text,
  birth_date text,
  birth_place text,
  death_date text,
  death_place text,
  occupation text,
  photo_file text,
  famc_id text  -- família on aquesta persona és filla (pot ser NULL si no es coneixen els pares)
);

create table families (
  id text primary key,
  husband_id text references persons(id),
  wife_id text references persons(id),
  marriage_date text,
  marriage_place text
);

alter table persons enable row level security;
alter table families enable row level security;

create policy "Lectura pública de persones" on persons for select using (true);
create policy "Lectura pública de famílies" on families for select using (true);
