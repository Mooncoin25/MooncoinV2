// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    Mooncoin v2 (MOON)
    - OpenZeppelin v5
    - Fee fissa 2.00% (200 bps) su trasferimenti
    - Fee NON modificabile
    - Nessuna whitelist/blacklist
    - Nessun mint dopo il deploy
    - Owner solo per eventuale renounce/transferOwnership (non ha funzioni che cambiano le fee)
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MooncoinV2 is ERC20, Ownable {
    // ---- Parametri fee fissi (immutabili) ----
    uint256 public constant FEE_BPS = 200;      // 2.00%
    uint256 public constant BPS = 10_000;       // base punti base

    // Indirizzo che riceve le fee (immutabile)
    address public immutable feeRecipient;

    /**
     * @param initialSupply  supply iniziale in wei (18 decimali).
     *                       Esempio: 1_000_000e18 per 1,000,000 MOON
     * 
     * feeRecipient è fissato al deployer (owner iniziale) e NON può essere cambiato.
     */
    constructor(uint256 initialSupply)
        ERC20("Mooncoin v2", "MOON")
        Ownable(msg.sender) // imposta l'owner al deployer (consigliato un multisig)
    {
        feeRecipient = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    /**
     * OpenZeppelin v5 usa _update per gestire i trasferimenti.
     * Applichiamo la fee SOLO sui trasferimenti normali (no mint/burn).
     * Esenzione fee per transazioni che coinvolgono direttamente il feeRecipient
     * per evitare doppi prelievi o edge-case.
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        // mint o burn o importi zero -> nessuna fee
        if (from == address(0) || to == address(0) || value == 0) {
            super._update(from, to, value);
            return;
        }

        // Se una delle parti è il feeRecipient, non applichiamo fee
        if (from == feeRecipient || to == feeRecipient) {
            super._update(from, to, value);
            return;
        }

        // Calcolo fee 2%
        uint256 fee = (value * FEE_BPS) / BPS;
        uint256 net = value - fee;

        // Trasferiamo la fee al feeRecipient e il netto al destinatario
        super._update(from, feeRecipient, fee);
        super._update(from, to, net);
    }

    // Decimali standard ERC20 (18). Se vuoi un altro valore, cambia qui PRIMA del deploy.
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
