
-- psql -h postgres.localnet -U harvest -d harvest -f sql/test.sql

select
  concept_view.concept_id,
  concept_view.label,
  concept_view.parent_id,

  data_parameter.record_id

/*
  case concept_view.label
    when concept_view.label  then data_parameter.record_id 
    else null
  end
  as record_id
*/
  -- record.uuid
from concept_view
left join data_parameter on data_parameter.concept_id = concept_view.concept_id and concept_view.label = 'mooring' 

order by concept_id
;




-- left join record on data_parameter.record_id = record.id
-- where concept_view.label = 'mooring'
-- order by concept_view

-- transfer_link - contains protocol and resource


