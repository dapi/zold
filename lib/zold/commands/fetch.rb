# frozen_string_literal: true

require 'zold'

module Zold
  module Commands
    # Fetches all copies of wallet from specified remote nodes and save the best one
    #
    class Fetch < Base

      attribute :remote_node, Array[RemoteNode]
      attribute :copies, Array[WalletCopy]

      # TODO move constant into Zold module
      DEFAULT_THREADS = [Concurrent.processor_count / 2, 2].max

      # TODO Probably better to exclude into CommandLine class
      command_line_options do |o|
        o.banner  = "Usage: zold fetch [ID...] [options] Available options:"
        o.bool    '--ignore-score-weakness', 'Don\'t complain when their score is too weak', default: false
        o.array   '--ignore-node',           'Ignore this node and don\'t fetch from it', default: []
        o.bool    '--quiet-if-absent',       'Don\'t fail if the wallet is absent in all remote nodes', default: false
        o.string  '--network',               'The name of the network we work in', default: 'test'
        o.integer '--threads',               "How many threads to use for fetching wallets (default: #{DEFAULT_THREADS})", default: DEFAULT_THREADS
        o.bool    '--help',                  'Print instructions'
      end

      private

      def perform(custom_wallet_ids, threads: 1, ignore_node: [])
        wallets_to_fetch = custom_wallet_ids.map { |id| Wallet.build(id) }.presence ||
          Universe.wallets

        nodes_to_fetch = remote_nodes - [ignore_node]

        Parallel.map wallets_to_fetch, in_threads: threads do |wallet|
          nodes_to_fetch.each do |remote_node|
            fetch_wallet_and_add_to_copy wallet, remote_node
          end
        end
      end

      def fetch_wallet_and_add_to_copy wallet, remote
        bm = Benchmark.measure do
          # Fetch wallet from specific remote by the most suitable way: with timeouts, validates and parsing
          copies.add remote.wallets_resources.get Routes.wallet_path(wallet)
        end
        logger.info "Successful finish (#{bm.real})"
      end
    end
  end
end
