"""Build one SQL Editor script from the canonical migration and catalog seed."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
migration_path = ROOT / "migrations" / "20261030120000_echoes_v22_legacy_update.sql"
seed_path = ROOT / "seeds" / "memory_catalog.sql"
output_path = ROOT / "ECHOES_V2.2_FULL_SETUP.sql"

migration = migration_path.read_text(encoding="utf-8").strip()
seed_lines = seed_path.read_text(encoding="utf-8").splitlines()
nonempty = [
    i
    for i, line in enumerate(seed_lines)
    if line.strip() and not line.lstrip().startswith("--")
]
assert seed_lines[nonempty[0]].strip().lower() == "begin;"
assert seed_lines[nonempty[-1]].strip().lower() == "commit;"
seed_lines[nonempty[0]] = ""
seed_lines[nonempty[-1]] = ""
seed = "\n".join(seed_lines).strip()

bundle = f"""-- ECHOES V2.2 — script completo de instalação (schema + catálogo educativo)
-- Antes de executar: rode supabase/qa/preflight_remote.sql e confira conflitos.
-- CREATE TABLE IF NOT EXISTS não corrige uma tabela preexistente com formato diferente.
-- Esta transação não apaga tabelas nem dados de jogadores; o seed atualiza textos pelos IDs estáveis.
-- Se houver erro, a transação não deve ser concluída. Leia a mensagem antes de tentar novamente.

begin;

-- MIGRATION: {migration_path.name}
{migration}

-- SEED: {seed_path.name}
{seed}

commit;
"""
output_path.write_text(bundle, encoding="utf-8", newline="\n")
assert bundle.lower().count("begin;") == 1
assert bundle.lower().count("commit;") == 1
assert "drop table" not in bundle.lower()
print(f"Generated {output_path.name}: {output_path.stat().st_size} bytes")
