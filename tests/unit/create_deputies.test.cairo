#[cfg(test)]
mod tests {
    use super::{Storage, DeputieABIImpl, Deputies};
    use starknet::testing::start_test_state;

    #[test]
    fn test_create_and_deactivate_deputie() {
        let mut state = start_test_state();
        let mut contract = state.deploy_contract::<Storage>((), ());

        // Crear un diputado individual
        contract.create_deputie('Luis', 'Gomez', 'Mora', 'PartidoB');
        let d1 = contract.deputies.read(0);
        assert(d1.name == 'Luis', 'Nombre incorrecto');
        assert(d1.active == true, 'Debe estar activo');

        // Desactivar diputado
        contract.desactivate_deputie(0);
        let d1_updated = contract.deputies.read(0);
        assert(d1_updated.active == false, 'Debe estar desactivado');
    }

    #[test]
    fn test_create_multiple_deputies() {
        let mut state = start_test_state();
        let mut contract = state.deploy_contract::<Storage>((), ());

        // Crear múltiples diputados con create_deputies
        let deputies = array![
            Deputies { name: 'Ana', first_surname: 'Torres', second_surname: 'Vega', political_party: 'PartidoX', active: true },
            Deputies { name: 'Jose', first_surname: 'Diaz', second_surname: 'Luna', political_party: 'PartidoY', active: true }
        ];
        contract.create_deputies(deputies);

        // Verificar
        let d0 = contract.deputies.read(0);
        let d1 = contract.deputies.read(1);

        assert(d0.name == 'Ana', 'Nombre incorrecto en 0');
        assert(d1.name == 'Jose', 'Nombre incorrecto en 1');

        let next_id = contract.next_deputie_id.read();
        assert(next_id == 2, 'Debe haberse actualizado el ID');
    }
}
