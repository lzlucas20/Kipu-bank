// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

/// @title KipuBank
/// @author Lucas Zunino
/// @notice Un Smart Contract para depositar y retirar ETH con trazabilidad completa
/// @dev Implementa patrones de seguridad como checks-effects-interactions y custom errors
contract KipuBank {
    
    /// @notice Límite máximo permitido para un retiro individual
    uint256 public immutable LIMITE_RETIRO;
    
    /// @notice Capacidad máxima total del banco
    uint256 public immutable CAPACIDAD_BANCO;
    
    /// @notice Depósito mínimo requerido
    uint256 public constant DEPOSITO_MINIMO = 0.01 ether;
    
    /// @notice Mapeo para guardar el saldo de cada usuario
    mapping(address => uint256) public bovedas;
    
    /// @notice Mapeo que cuenta el número de depósitos por usuario
    mapping(address => uint256) public userContadorDepositos;
    
    /// @notice Mapeo que cuenta el número de retiros por usuario
    mapping(address => uint256) public userContadorRetiros;
    
    /// @notice Mapeo privado que indica si un usuario ha depositado alguna vez
    mapping(address => bool) private haDepositado;
    
    /// @notice Monto total depositado en el banco
    uint256 public totalDepositado;
    
    /// @notice Cantidad total de usuarios que han realizado depósitos y mantienen saldo
    uint256 public totalUsuarios;
    
    /// @notice Se emite cuando un usuario realiza un depósito
    /// @param depositante Dirección del que realiza el depósito
    /// @param monto Cantidad de ETH depositada
    /// @param nuevoSaldo Saldo actualizado del usuario
    event Deposito(
        address indexed depositante, 
        uint256 monto, 
        uint256 nuevoSaldo
    );
    
    /// @notice Se emite cuando un usuario realiza un retiro
    /// @param retirador Dirección que realiza el retiro
    /// @param monto Cantidad de ETH retirada
    /// @param saldoRestante Saldo restante del usuario
    event Retiro(
        address indexed retirador, 
        uint256 monto, 
        uint256 saldoRestante
    );
    
    /// @notice Error cuando el depósito es menor al mínimo permitido
    error DepositoMuyPequeno();
    
    /// @notice Error cuando la capacidad del banco sería excedida
    /// @param totalActual Monto total depositado actualmente
    /// @param intentoDeposito Monto que se intenta depositar
    /// @param capacidadBanco Capacidad máxima del banco
    error CapacidadBancoExcedida(uint256 totalActual, uint256 intentoDeposito, uint256 capacidadBanco);
    
    /// @notice Error cuando el retiro excede el límite permitido
    /// @param solicitado Monto solicitado para retirar
    /// @param limite Límite máximo de retiro
    error RetiroExcedeLimite(uint256 solicitado, uint256 limite);
    
    /// @notice Error cuando el saldo es insuficiente
    /// @param solicitado Monto solicitado para retirar
    /// @param disponible Saldo disponible del usuario
    error SaldoInsuficiente(uint256 solicitado, uint256 disponible);
    
    /// @notice Error cuando la transferencia de ETH falla
    error TransferenciaFallida();
    
    /// @notice Error cuando se intenta usar un monto inválido (0)
    error MontoInvalido();
    
    /// @notice Error cuando el usuario no tiene depósitos
    error SinDepositos();
    
    /// @notice Error en los parámetros del constructor
    error ParametrosInvalidos();

    /// @notice Valida que el monto sea mayor a 0
    /// @param monto Cantidad a validar
    modifier montoValido(uint256 monto) {
        if (monto == 0) {
            revert MontoInvalido();
        }
        _;
    }
    
    /// @notice Valida que el usuario tenga saldo en su bóveda
    modifier tieneSaldoBoveda() {
        if (bovedas[msg.sender] == 0) {
            revert SinDepositos();
        }
        _;
    }
    
    /// @notice Constructor que inicializa los parámetros del banco
    /// @param _limiteRetiro Límite máximo para cada retiro
    /// @param _capacidadBanco Capacidad máxima del banco
    constructor(uint256 _limiteRetiro, uint256 _capacidadBanco) {
        if (_limiteRetiro <= DEPOSITO_MINIMO) {
            revert ParametrosInvalidos();
        }
        if (_capacidadBanco <= DEPOSITO_MINIMO) {
            revert ParametrosInvalidos();
        }
        if (_capacidadBanco <= _limiteRetiro) {
            revert ParametrosInvalidos();
        }
        
        LIMITE_RETIRO = _limiteRetiro;
        CAPACIDAD_BANCO = _capacidadBanco;
    }

    /// @notice Permite a un usuario depositar ETH en el banco
    /// @dev Sigue el patrón checks-effects-interactions donde se valida el monto y la capacidad del banco para poder realizar el depósito
    /// @dev Actualiza el saldo del usuario y el total depositado
    function depositar() external payable montoValido(msg.value) {
        // -----checks-----
        if (msg.value < DEPOSITO_MINIMO) {
            revert DepositoMuyPequeno();
        }
        
        if (totalDepositado + msg.value > CAPACIDAD_BANCO) {
            revert CapacidadBancoExcedida(totalDepositado, msg.value, CAPACIDAD_BANCO);
        }
        
        // -----effects-----
        if (!haDepositado[msg.sender]) {
            haDepositado[msg.sender] = true;
            totalUsuarios++;
        }
        
        bovedas[msg.sender] += msg.value;
        totalDepositado += msg.value;
        userContadorDepositos[msg.sender]++;
        
        // -----emit-----
        emit Deposito(msg.sender, msg.value, bovedas[msg.sender]);
    }
    
    /// @notice Permite a un usuario retirar ETH del banco
    /// @param monto Cantidad de ETH a retirar
    /// @dev Valida el límite de retiro y saldo disponible antes de transferir
    /// @dev Sigue el patrón checks-effects-interactions
    function retirar(uint256 monto) external montoValido(monto) tieneSaldoBoveda {
        // -----checks-----
        if (monto > LIMITE_RETIRO) {
            revert RetiroExcedeLimite(monto, LIMITE_RETIRO);
        }
        
        uint256 saldoUsuario = bovedas[msg.sender];
        if (monto > saldoUsuario) {
            revert SaldoInsuficiente(monto, saldoUsuario);
        }
        
        // -----effects-----
        bovedas[msg.sender] -= monto;
        totalDepositado -= monto;
        userContadorRetiros[msg.sender]++;
        
        if (bovedas[msg.sender] == 0) {
            _actualizarEstadoUsuario(msg.sender);
        }
        
        // -----emit-----
        emit Retiro(msg.sender, monto, bovedas[msg.sender]);
        
        // -----interactions-----
        (bool success, ) = msg.sender.call{value: monto}("");
        if (!success) {
            revert TransferenciaFallida();
        }
    }
    
    /// @notice Devuelve el saldo de ETH en la bóveda de un usuario
    /// @param usuario Dirección del usuario
    /// @return saldo El saldo de ETH del usuario
    function obtenerSaldoBoveda(address usuario) external view returns (uint256 saldo) {
        return bovedas[usuario];
    }
    
    /// @notice Devuelve los registros completos de un usuario
    /// @param usuario Dirección del usuario
    /// @return saldo El saldo actual de ETH del usuario
    /// @return depositos Número total de depósitos realizados
    /// @return retiros Número total de retiros realizados
    function registrosUsuario(address usuario) external view returns (
        uint256 saldo,
        uint256 depositos,
        uint256 retiros
    ) {
        return (
            bovedas[usuario],
            userContadorDepositos[usuario],
            userContadorRetiros[usuario]
        );
    }

    /// @notice Devuelve la capacidad disponible restante del banco
    /// @return capacidadRestante La cantidad de ETH que aún puede depositarse
    function obtenerCapacidadRestante() external view returns (uint256 capacidadRestante) {
        return CAPACIDAD_BANCO - totalDepositado;
    }
    
    /// @notice Actualiza el estado de un usuario cuando su saldo llega a 0
    /// @param usuario Dirección del usuario a actualizar
    function _actualizarEstadoUsuario(address usuario) private {
        if (bovedas[usuario] == 0 && haDepositado[usuario]) {
            haDepositado[usuario] = false;
            if (totalUsuarios > 0) {
                totalUsuarios--;
            }
        }
    }
    
    /// @notice Valida que una dirección no sea la dirección cero
    /// @param addr Dirección a validar
    /// @return isValid True si la dirección es válida, false en caso contrario
    function _esDireccionValida(address addr) private pure returns (bool isValid) {
        return addr != address(0);
    }
    
    /// @notice Permite recibir ETH directamente y realizar un depósito automático
    /// @dev Llamada cuando se envía ETH sin datos al contrato
    receive() external payable {
        if (msg.value > 0) {
            this.depositar{value: msg.value}();
        }
    }
}