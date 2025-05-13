%lang starknet

use starkware.starknet.common.syscalls import get_caller_address
from src.names_registry import NamesRegistry

@contract_interface
namespace INamesRegistry {
    func register_name(name: felt) {
    }

    func get_name_owner(name: felt) -> (owner: felt) {
    }

    func get_total_names() -> (total: felt) {
    }
}

@contract
contract TestContract {
}

@test
func test_register_name() {
    let contract_address = deploy_contract('NamesRegistry');
    let caller = get_caller_address();

    // Registrar nombre
    INamesRegistry.register_name(contract_address, 'starknet');

    // Verificar dueño
    let (owner) = INamesRegistry.get_name_owner(contract_address, 'starknet');
    assert owner = caller;

    // Verificar contador
    let (total) = INamesRegistry.get_total_names(contract_address);
    assert total = 1;
}

@test
func test_cannot_reregister_name() {
    let contract_address = deploy_contract('NamesRegistry');
    
    // Registrar nombre
    INamesRegistry.register_name(contract_address, 'cairo');
    
    // Intentar registrar nuevamente (debe fallar)
    %{
        from starkware.starknet.testing.contract import StarknetContract
        contract: StarknetContract = ids.contract_address
        
        try:
            contract.register_name('cairo').execute()
            assert False, "Should have failed"
        except:
            pass
    %}
}