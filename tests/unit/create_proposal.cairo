%lang starknet

from src.lib import (
    admin_address, proposal_count, proposal_description, proposal_votes, 
    initialize, add_proposal, vote
)

@contract_interface
namespace IVotingContract:
    func initialize(admin: felt):
    end
    
    func add_proposal(description: felt) -> (new_index: felt):
    end
    
    func vote(proposal_index: felt):
    end

@external
func test_admin_functions():
    alloc_locals
    local contract_address: felt
    local admin: felt = 123
    local user: felt = 456
    
    # 1. Desplegar e inicializar contrato
    %{
        contract_address = deploy_contract('voting_contract')
        IVotingContract.initialize(contract_address, admin)
    %}
    
    # 2. Verificar admin
    let (stored_admin) = admin_address.read()
    assert stored_admin = admin
    
    # 3. Test: Solo admin puede agregar propuestas
    %{
        # Llamada como admin (debería funcionar)
        IVotingContract.add_proposal(contract_address, admin, 'Propuesta 1')
        
        # Llamada como usuario (debería fallar)
        try:
            IVotingContract.add_proposal(contract_address, user, 'Propuesta 2')
            assert False, 'Usuario normal no debería poder agregar propuestas'
        except:
            pass
    %}
    return ()
end

@external
func test_voting_flow():
    alloc_locals
    local contract_address: felt
    local admin: felt = 123
    local user1: felt = 456
    local user2: felt = 789
    
    # 1. Desplegar e inicializar
    %{
        contract_address = deploy_contract('voting_contract')
        IVotingContract.initialize(contract_address, admin)
        
        # Agregar propuesta
        let (prop_index) = IVotingContract.add_proposal(
            contract_address, admin, 'Votemos!')
        
        # Usuario 1 vota
        IVotingContract.vote(contract_address, user1, prop_index)
        
        # Verificar voto registrado
        let (votes) = proposal_votes.read(prop_index)
        assert votes == 1, 'Voto no registrado correctamente'
        
        # Intentar voto duplicado (debería fallar)
        try:
            IVotingContract.vote(contract_address, user1, prop_index)
            assert False, 'No debería permitir votos duplicados'
        except:
            pass
    %}
    return ()
end