#[cfg(test)]
mod tests {
    use super::{President, PresidentABIImpl, PresidentABI, Storage};
    use starknet::testing::start_test_state;
    use starknet::contract::Contract;
    use starknet::contract::ContractAddress;

    #[test]
    fn test_create_and_deactivate_president() {
        // Iniciar estado de prueba
        let mut state = start_test_state();
        let contract_address = ContractAddress::from(1);

        // Instanciar el contrato
        let mut contract = state.deploy_contract::<Storage>((), ());

        // Crear presidente
        contract.create_president(
            'Juan', 'Pérez', 'López', 'PartidoA'
        );

        // Leer presidente creado (ID 0)
        let pres_0 = contract.presidents.read(0);
        assert(pres_0.name == 'Juan', 'Nombre incorrecto');
        assert(pres_0.first_surname == 'Pérez', 'Apellido 1 incorrecto');
        assert(pres_0.second_surname == 'López', 'Apellido 2 incorrecto');
        assert(pres_0.political_party == 'PartidoA', 'Partido incorrecto');
        assert(pres_0.active == true, 'El presidente debería estar activo');

        // Verificar contador
        let next_id = contract.next_president_id.read();
        assert(next_id == 1, 'El ID siguiente debería ser 1');

        // Desactivar presidente
        contract.deactivate_president(0);
        let pres_0_after = contract.presidents.read(0);
        assert(pres_0_after.active == false, 'El presidente debería estar desactivado');
    }
}
