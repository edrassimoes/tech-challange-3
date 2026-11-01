INSERT INTO api_keys (name, key_hash)
VALUES ('local-services', '8f2e895eb556e60f9ccfd8cd8e754d5379ef320570fd47a8307e73968a10c3eb')
ON CONFLICT (key_hash) DO NOTHING;
