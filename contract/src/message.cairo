use core::array::Array;
use starknet::ContractAddress;

// Define the contract interface
#[starknet::interface]
pub trait IMessageStorage<TContractState> {
    fn store_message(ref self: TContractState, recipient: ContractAddress, message: ByteArray);
    fn get_message(self: @TContractState, recipient: ContractAddress, index: u64) -> ByteArray;
    fn get_all_messages(self: @TContractState, recipient: ContractAddress) -> Array<ByteArray>;
    fn delete_message(ref self: TContractState, recipient: ContractAddress, index: u64);
    fn delete_all_messages(ref self: TContractState, recipient: ContractAddress);
}

// Define the contract module
#[starknet::contract]
pub mod MessageStorage {
    use core::array::{Array, ArrayTrait};
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, Vec, VecTrait,
        StorageMapReadAccess, StorageMapWriteAccess,
    };
    use super::IMessageStorage;

    // Define storage variables
    #[storage]
    struct Storage {
        messages: Map<ContractAddress, Vec<ByteArray>>,
        message_counter: Map<ContractAddress, u64>,
    }

    // Implement the contract interface
    #[abi(embed_v0)]
    impl MessageStorageImpl of IMessageStorage<ContractState> {
        // Store a message
        fn store_message(ref self: ContractState, recipient: ContractAddress, message: ByteArray) {
            // Check if message is empty
            assert(message.len() != 0, 'Message cannot be empty');
            
            let recipient_messages = self.messages.entry(recipient);

            // Append the message to the recipient's message vector
            recipient_messages.push(message);
            
            // Get the current counter for the recipient
            let current_index = self.message_counter.read(recipient);
            
            // Store the message
            self.messages.write((recipient, current_index), message);
            
            // Increment the counter
            self.message_counter.write(recipient, current_index + 1);
        }

        // Get a specific message
        fn get_message(self: @ContractState, recipient: ContractAddress, index: u64) -> ByteArray {
            // Check if the index is valid
            let total_messages = self.message_counter.read(recipient);
            assert(index < total_messages, 'Index out of bounds');
            
            // Return the message
            self.messages.read((recipient, index))
        }

        // Get all messages for a recipient
        fn get_all_messages(self: @ContractState, recipient: ContractAddress) -> Array<ByteArray> {
            // Get the total number of messages for the recipient
            let total_messages = self.message_counter.read(recipient);
            
            // Create a new array to store the messages
            let mut messages: Array<ByteArray> = ArrayTrait::new();
            
            // Iterate through the recipient's messages and append them to the array
            let mut i: u64 = 0;
            while i < total_messages {
                messages.append(self.messages.read((recipient, i)));
                i += 1;
            }
            
            // Return the array of messages
            messages
        }

        // Delete a specific message by index
        fn delete_message(ref self: ContractState, recipient: ContractAddress, index: u64) {
            // Access storage vector
            let messages = self.messages.entry(recipient);
            let total_messages = messages.len();

            // Validate index
            assert(index < total_messages, 'Invalid message index');

            // A new array to store the messages
            let mut new_messages: Array<ByteArray> = ArrayTrait::new();

            // Rebuild messages without the deleted index
            let mut i = 0;
            while let Option::Some(message) = messages.pop() {
                if i != index {
                    new_messages.append(message);
                }
                i += 1;
            }
            for _ in 0..new_messages.len() {
                messages.push(new_messages.pop_front().unwrap());
            }
        }

        // Delete all messages for a recipient
        fn delete_all_messages(ref self: ContractState, recipient: ContractAddress) {
            let recipient_messages = self.messages.entry(recipient);

            while let Option::Some(_) = recipient_messages.pop() {
                // Continue popping until all messages are deleted
            }
        }
    }
}

// Define a new trait for the Profile System
#[starknet::interface]
pub trait IProfileSystem<TContractState> {
    fn set_profile(
        ref self: TContractState, username: felt252, name: felt252, profile_pic_url: felt252,
    );
    fn get_profile(self: @TContractState, username: felt252) -> (felt252, felt252);
}

// Implement the Profile System
#[starknet::contract]
pub mod ProfileSystem {
    use core::array::{Array, ArrayTrait};
    use starknet::ContractAddress;
    use starknet::storage::{Map, Vec};
    use super::IProfileSystem;

    // Define storage variables
    #[storage]
    struct Storage {
        profiles: Map<felt252, (felt252, felt252)>,
    }

    #[abi(embed_v0)]
    impl ProfileSystemImpl of IProfileSystem<ContractState> {
        fn set_profile(
            ref self: ContractState, username: felt252, name: felt252, profile_pic_url: felt252,
        ) {
            self.profiles.write(username, (name, profile_pic_url));
        }

        fn get_profile(self: @ContractState, username: felt252) -> (felt252, felt252) {
            self.profiles.read(username)
        }
    }
}
