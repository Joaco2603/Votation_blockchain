// use starknet::ContractAddress;
// use starknet::get_caller_address;

// #[starknet::interface]
// trait CreateRulesABI<TContractState> {
//     fn set_rules(ref self: TContractState, candidates: Array<felt252>,start_time: u64,end_time: u64)->felt252;
// }

// #[derive(Drop, Serde)]
// struct ElectionRule {
//     candidates: Array<felt252>, // Lista de candidatos
//     start_time: u64,
//     end_time: u64,
// }

// #[starknet::contract]
// mod VotingRules {
//     use super::{ContractAddress, get_caller_address ,ElectionRule, CreateRulesABI};
//     use starknet::storage::{StorageMapReadAccess, StorageMapWriteAccess};
//     use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};

//     #[storage]
//     struct Storage {
//         rules: Map<ContractAddress, ElectionRule>,
//     }

//     #[abi(embed_v0)]
//     impl CreateRulesABIImpl of CreateRulesABI<ContractState> {
//         fn set_rules(ref self: votations::contracts::create_proposal::VotingRules::ContractState, candidates: core::array::Array::<core::felt252>, start_time: core::integer::u64, end_time: core::integer::u64) -> core::felt252 {
//             let caller = get_caller_address();

//             let rule = ElectionRule{
//                 candidates,
//                 start_time,
//                 end_time,
//             };

//             return self.rules.write(caller, rule);
//         }        
//     }
// }