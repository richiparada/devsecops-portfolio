pipeline {
    agent any
    
    environment {
        // Azure Configuration
        ACR_NAME = 'devsecopsacr'
        ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"
        AKS_CLUSTER = 'devsecops-aks'
        AKS_RESOURCE_GROUP = 'devsecops-rg'
        
        // Image configuration
        API_IMAGE_NAME = 'api'
        FRONTEND_IMAGE_NAME = 'frontend'
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7)}"
        
        // Security thresholds
        TRIVY_SEVERITY = 'HIGH,CRITICAL'
        SEMGREP_SEVERITY = 'ERROR'
        
        // Namespaces
        STAGING_NAMESPACE = 'staging'
        PROD_NAMESPACE = 'production'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Checking out code..."
                    checkout scm
                    sh 'git log -1 --pretty=format:"%h - %an: %s"'
                }
            }
        }
        
        stage('Build & Test') {
            parallel {
                stage('API Tests') {
                    steps {
                        script {
                            echo "🧪 Running API unit tests..."
                            dir('app/api') {
                                sh '''
                                    python -m venv venv
                                    . venv/bin/activate
                                    pip install -r requirements.txt
                                    pytest tests/ --cov=src --cov-report=xml --cov-report=html --junitxml=test-results.xml
                                '''
                            }
                            
                            // Publish test results
                            junit 'app/api/test-results.xml'
                            publishHTML([
                                reportDir: 'app/api/htmlcov',
                                reportFiles: 'index.html',
                                reportName: 'API Coverage Report'
                            ])
                        }
                    }
                }
                
                stage('Frontend Tests') {
                    steps {
                        script {
                            echo "🧪 Running frontend tests..."
                            dir('app/frontend') {
                                sh '''
                                    npm ci
                                    npm run test -- --coverage --watchAll=false
                                    npm run lint
                                '''
                            }
                        }
                    }
                }
            }
        }
        
        stage('SAST - Static Analysis') {
            parallel {
                stage('Semgrep Scan') {
                    steps {
                        script {
                            echo "🔍 Running SAST with Semgrep..."
                            sh '''
                                docker run --rm \
                                    -v $(pwd):/src \
                                    returntocorp/semgrep semgrep \
                                    --config=p/owasp-top-ten \
                                    --config=p/security-audit \
                                    --sarif --output=/src/semgrep-report.sarif \
                                    /src
                            '''
                            
                            // Archive report
                            archiveArtifacts artifacts: 'semgrep-report.sarif', allowEmptyArchive: true
                            
                            // Parse and fail on high severity
                            sh '''
                                if grep -q '"level": "error"' semgrep-report.sarif; then
                                    echo "❌ SAST: High severity issues found!"
                                    exit 1
                                fi
                            '''
                        }
                    }
                }
                
                stage('Secrets Scanning') {
                    steps {
                        script {
                            echo "🔐 Scanning for secrets with Gitleaks..."
                            sh '''
                                docker run --rm \
                                    -v $(pwd):/path \
                                    zricethezav/gitleaks:latest detect \
                                    --source="/path" \
                                    --report-path="/path/gitleaks-report.json" \
                                    --report-format=json \
                                    --no-git || true
                            '''
                            
                            archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
                            
                            // Fail if secrets found
                            sh '''
                                if [ -f gitleaks-report.json ] && [ -s gitleaks-report.json ]; then
                                    echo "❌ Secrets detected in code!"
                                    cat gitleaks-report.json
                                    exit 1
                                fi
                            '''
                        }
                    }
                }
            }
        }
        
        stage('SCA - Dependency Scan') {
            steps {
                script {
                    echo "📦 Scanning dependencies for vulnerabilities..."
                    
                    // Python dependencies
                    sh '''
                        docker run --rm \
                            -v $(pwd)/app/api:/src \
                            owasp/dependency-check:latest \
                            --scan /src \
                            --format HTML \
                            --format JSON \
                            --out /src/dependency-check-report \
                            --enableExperimental
                    '''
                    
                    archiveArtifacts artifacts: 'app/api/dependency-check-report/*', allowEmptyArchive: true
                    
                    publishHTML([
                        reportDir: 'app/api/dependency-check-report',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'Dependency Check Report'
                    ])
                }
            }
        }
        
        stage('Build Container Images') {
            parallel {
                stage('Build API Image') {
                    steps {
                        script {
                            echo "🐳 Building API Docker image..."
                            dir('app/api') {
                                sh """
                                    docker build -t ${API_IMAGE_NAME}:${IMAGE_TAG} .
                                    docker tag ${API_IMAGE_NAME}:${IMAGE_TAG} ${API_IMAGE_NAME}:latest
                                """
                            }
                        }
                    }
                }
                
                stage('Build Frontend Image') {
                    steps {
                        script {
                            echo "🐳 Building Frontend Docker image..."
                            dir('app/frontend') {
                                sh """
                                    docker build -t ${FRONTEND_IMAGE_NAME}:${IMAGE_TAG} .
                                    docker tag ${FRONTEND_IMAGE_NAME}:${IMAGE_TAG} ${FRONTEND_IMAGE_NAME}:latest
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Container Security Scan') {
            parallel {
                stage('Scan API Image') {
                    steps {
                        script {
                            echo "🛡️ Scanning API image with Trivy..."
                            sh """
                                docker run --rm \
                                    -v /var/run/docker.sock:/var/run/docker.sock \
                                    aquasec/trivy image \
                                    --severity ${TRIVY_SEVERITY} \
                                    --exit-code 1 \
                                    --format json \
                                    --output trivy-api-report.json \
                                    ${API_IMAGE_NAME}:${IMAGE_TAG}
                            """
                            
                            archiveArtifacts artifacts: 'trivy-api-report.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('Scan Frontend Image') {
                    steps {
                        script {
                            echo "🛡️ Scanning Frontend image with Trivy..."
                            sh """
                                docker run --rm \
                                    -v /var/run/docker.sock:/var/run/docker.sock \
                                    aquasec/trivy image \
                                    --severity ${TRIVY_SEVERITY} \
                                    --exit-code 1 \
                                    --format json \
                                    --output trivy-frontend-report.json \
                                    ${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}
                            """
                            
                            archiveArtifacts artifacts: 'trivy-frontend-report.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        stage('IaC Security Scan') {
            parallel {
                stage('Scan Terraform') {
                    steps {
                        script {
                            echo "🏗️ Scanning Terraform with Checkov..."
                            sh '''
                                docker run --rm \
                                    -v $(pwd):/tf \
                                    bridgecrew/checkov \
                                    -d /tf/terraform \
                                    --framework terraform \
                                    --output json \
                                    --output-file-path /tf \
                                    --soft-fail || true
                            '''
                            
                            archiveArtifacts artifacts: 'results_json.json', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('Scan Kubernetes') {
                    steps {
                        script {
                            echo "☸️ Scanning Kubernetes manifests with Checkov..."
                            sh '''
                                docker run --rm \
                                    -v $(pwd):/k8s \
                                    bridgecrew/checkov \
                                    -d /k8s/k8s \
                                    --framework kubernetes \
                                    --output json \
                                    --output-file-path /k8s \
                                    --soft-fail || true
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Generate SBOM') {
            steps {
                script {
                    echo "📋 Generating Software Bill of Materials..."
                    sh """
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            anchore/syft:latest \
                            ${API_IMAGE_NAME}:${IMAGE_TAG} \
                            -o cyclonedx-json > sbom-api.json
                        
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            anchore/syft:latest \
                            ${FRONTEND_IMAGE_NAME}:${IMAGE_TAG} \
                            -o cyclonedx-json > sbom-frontend.json
                    """
                    
                    archiveArtifacts artifacts: 'sbom-*.json', allowEmptyArchive: false
                }
            }
        }
        
        stage('Push to ACR') {
            steps {
                script {
                    echo "📤 Pushing images to Azure Container Registry..."
                    withCredentials([azureServicePrincipal('azure-sp')]) {
                        sh """
                            az login --service-principal -u \$AZURE_CLIENT_ID -p \$AZURE_CLIENT_SECRET --tenant \$AZURE_TENANT_ID
                            az acr login --name ${ACR_NAME}
                            
                            # Tag and push API
                            docker tag ${API_IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${API_IMAGE_NAME}:${IMAGE_TAG}
                            docker tag ${API_IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${API_IMAGE_NAME}:latest
                            docker push ${ACR_LOGIN_SERVER}/${API_IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${ACR_LOGIN_SERVER}/${API_IMAGE_NAME}:latest
                            
                            # Tag and push Frontend
                            docker tag ${FRONTEND_IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}
                            docker tag ${FRONTEND_IMAGE_NAME}:${IMAGE_TAG} ${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE_NAME}:latest
                            docker push ${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                script {
                    echo "🚀 Deploying to Staging environment..."
                    withCredentials([azureServicePrincipal('azure-sp')]) {
                        sh """
                            az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER} --overwrite-existing
                            
                            helm upgrade --install devsecops-app ./k8s/helm-chart \
                                --namespace ${STAGING_NAMESPACE} \
                                --create-namespace \
                                --set api.image.repository=${ACR_LOGIN_SERVER}/${API_IMAGE_NAME} \
                                --set api.image.tag=${IMAGE_TAG} \
                                --set frontend.image.repository=${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE_NAME} \
                                --set frontend.image.tag=${IMAGE_TAG} \
                                --set environment=staging \
                                --wait \
                                --timeout 5m
                            
                            # Wait for rollout
                            kubectl rollout status deployment/devsecops-api -n ${STAGING_NAMESPACE}
                            kubectl rollout status deployment/devsecops-frontend -n ${STAGING_NAMESPACE}
                        """
                    }
                }
            }
        }
        
        stage('DAST - Dynamic Security Testing') {
            steps {
                script {
                    echo "🎯 Running DAST with OWASP ZAP..."
                    
                    // Get staging URL
                    def stagingUrl = sh(
                        script: "kubectl get ingress -n ${STAGING_NAMESPACE} -o jsonpath='{.items[0].spec.rules[0].host}'",
                        returnStdout: true
                    ).trim()
                    
                    sh """
                        docker run --rm \
                            -v \$(pwd):/zap/wrk:rw \
                            owasp/zap2docker-stable zap-baseline.py \
                            -t http://${stagingUrl} \
                            -r zap-report.html \
                            -J zap-report.json \
                            -w zap-report.md \
                            || true
                    """
                    
                    archiveArtifacts artifacts: 'zap-report.*', allowEmptyArchive: true
                    
                    publishHTML([
                        reportDir: '.',
                        reportFiles: 'zap-report.html',
                        reportName: 'OWASP ZAP Report'
                    ])
                }
            }
        }
        
        stage('Manual Approval') {
            steps {
                script {
                    echo "⏸️ Waiting for manual approval to deploy to Production..."
                    
                    // Display summary
                    def summary = """
                    ═══════════════════════════════════════════════
                    📊 SECURITY SCAN SUMMARY
                    ═══════════════════════════════════════════════
                    ✅ SAST (Semgrep): Passed
                    ✅ Secrets Scan (Gitleaks): Passed
                    ✅ SCA (Dependency Check): Completed
                    ✅ Container Scan (Trivy): Passed
                    ✅ IaC Scan (Checkov): Completed
                    ✅ SBOM Generated: Yes
                    ✅ DAST (OWASP ZAP): Completed
                    
                    🏷️  Image Tag: ${IMAGE_TAG}
                    🌐 Staging URL: Check ingress
                    
                    Review all reports before approving production deployment.
                    ═══════════════════════════════════════════════
                    """
                    
                    echo summary
                    
                    input message: 'Deploy to Production?', 
                          ok: 'Deploy',
                          submitter: 'admin,release-manager'
                }
            }
        }
        
        stage('Deploy to Production') {
            steps {
                script {
                    echo "🚀 Deploying to Production environment..."
                    withCredentials([azureServicePrincipal('azure-sp')]) {
                        sh """
                            helm upgrade --install devsecops-app ./k8s/helm-chart \
                                --namespace ${PROD_NAMESPACE} \
                                --create-namespace \
                                --set api.image.repository=${ACR_LOGIN_SERVER}/${API_IMAGE_NAME} \
                                --set api.image.tag=${IMAGE_TAG} \
                                --set frontend.image.repository=${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE_NAME} \
                                --set frontend.image.tag=${IMAGE_TAG} \
                                --set environment=production \
                                --set replicaCount=3 \
                                --wait \
                                --timeout 10m
                            
                            # Wait for rollout
                            kubectl rollout status deployment/devsecops-api -n ${PROD_NAMESPACE}
                            kubectl rollout status deployment/devsecops-frontend -n ${PROD_NAMESPACE}
                            
                            # Verify health
                            kubectl get pods -n ${PROD_NAMESPACE}
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline completed successfully!"
            // Send notification (Slack, Teams, email, etc.)
        }
        
        failure {
            echo "❌ Pipeline failed!"
            // Send alert notification
        }
        
        always {
            echo "🧹 Cleaning up..."
            // Clean up Docker images
            sh '''
                docker image prune -f
            '''
        }
    }
}
