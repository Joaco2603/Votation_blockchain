#[cfg(test)]
mod tests {
    use super::VotingContract;
    use starknet::testing::start_test_state;
    use starknet::contract::ContractAddress;
    use starknet::context::testing::set_caller_address;
    use core::option::OptionTrait;

    #[test]
    fn test_vote_and_get_votes() {
        // Iniciar estado de test
        let mut state = start_test_state();
        let contract_address = ContractAddress::from(1);
        let mut contract = state.deploy_contract(VotingContract::contract(), ());

        // Simular que el caller es el address 100
        let voter1 = ContractAddress::from(100);
        set_caller_address(voter1);

        // Votar por el presidente con índice 1
        let president_index = 1;
        let secret_hash = 999; // no se usa en lógica aún, solo guardado

        contract.vote(president_index, secret_hash);

        // Verificar que el voto fue registrado
        let votes = contract.get_votes(president_index);
        assert(votes == 1, 'Expected 1 vote');

        // Intentar votar otra vez (debe fallar)
        let err = contract.vote(president_index, secret_hash).try_unwrap_err();
        assert(err.is_some(), 'Expected error on double voting');

        // Simular otro usuario y votar
        let voter2 = ContractAddress::from(200);
        set_caller_address(voter2);
        contract.vote(president_index, 888);

        let votes_after = contract.get_votes(president_index);
        assert(votes_after == 2, 'Expected 2 votes');
    }
}
