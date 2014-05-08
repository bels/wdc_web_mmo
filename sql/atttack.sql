--Functions
CREATE OR REPLACE FUNCTION execute_attack(defender_val UUID, attack_id_val UUID) RETURNS INTEGER AS $$
DECLARE
	attack_damage INTEGER;
	defense_val INTEGER;
	damage_to_deal INTEGER;
	new_hitpoints INTEGER;
BEGIN
	--for now this will be a simplistic attack_damage - defense = damage_taken
	SELECT damage INTO attack_damage FROM spell_template WHERE id = attack_id_val;
	defense_val := 1; --I need to think of a way to store/calculate defense
	damage_to_deal := attack_damage - defense_val;
	new_hitpoints := (SELECT hitpoints FROM live_entities WHERE entity_id = defender_val) - damage_to_deal;
	UPDATE live_entities SET hitpoints = new_hitpoints WHERE entity_id = defender_val;
	
	RETURN new_hitpoints;
END;
$$ LANGUAGE plpgsql;