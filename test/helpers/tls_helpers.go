// pubsubplus-go-client
//
// Copyright 2021-2025 Solace Corporation. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package helpers

import (
	"fmt"

	"solace.dev/go/messaging/pkg/solace/config"
	"solace.dev/go/messaging/test/constants"
	"solace.dev/go/messaging/test/testcontext"
)

// ConfigureSecureConnection creates a transport security strategy that disables hostname validation
// but still validates the certificate against the trust store. This is useful when connecting to
// a broker through a remote Docker daemon where the hostname in the certificate doesn't match
// the hostname or IP address that the client is connecting to.
func ConfigureSecureConnection() config.TransportSecurityStrategy {
	// Configure TLS with certificate validation but without hostname validation
	return config.NewTransportSecurityStrategy().WithCertificateValidation(true, false, constants.ValidFixturesPath, "")
}

// CreateSecureConfiguration returns a configuration for connecting to the broker using TLS
// with certificate validation but without hostname validation. This is useful when
// connecting to a broker through a remote Docker daemon where the hostname in the certificate
// doesn't match the hostname or IP address that the client is connecting to.
func CreateSecureConfiguration() config.ServicePropertyMap {
	connectionDetails := testcontext.Messaging()
	url := fmt.Sprintf("tcps://%s:%d", connectionDetails.Host, connectionDetails.MessagingPorts.SecurePort)
	config := config.ServicePropertyMap{
		config.ServicePropertyVPNName:                               connectionDetails.VPN,
		config.TransportLayerPropertyHost:                           url,
		config.AuthenticationPropertySchemeBasicUserName:            connectionDetails.Authentication.BasicUsername,
		config.AuthenticationPropertySchemeBasicPassword:            connectionDetails.Authentication.BasicPassword,
		config.TransportLayerPropertyReconnectionAttempts:           0,
		config.TransportLayerSecurityPropertyTrustStorePath:         constants.ValidFixturesPath,
		config.TransportLayerSecurityPropertyCertRejectExpired:      true,
		config.TransportLayerSecurityPropertyCertValidateServername: false,
		config.TransportLayerSecurityPropertyCertValidated:          true,
	}
	return config
}
