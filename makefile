# ===============================
# SaaS Accelerator - CustomerSite Deployment
# ===============================

# Configuration
RESOURCE_GROUP = saas-accelerator-us-2
APP_NAME = cnovate-test-saas-portal
PROJECT_PATH = ./src/CustomerSite/CustomerSite.csproj
PUBLISH_DIR = ./Publish/CustomerSite
ZIP_PATH = ./Publish/CustomerSite.zip
RUNTIME = win-x86
CONFIGURATION = Release

# Default target
deploy-customer-site: clean build zip push restart
	@echo "✅ Deployment completed successfully!"

# Step 1: Clean old artifacts
clean:
	@echo "🧹 Cleaning old build artifacts..."
	@rm -rf $(PUBLISH_DIR) $(ZIP_PATH)

# Step 2: Build and publish for Windows App Service (.NET 8)
build:
	@echo "⚙️  Publishing CustomerSite for runtime $(RUNTIME)..."
	@dotnet publish $(PROJECT_PATH) -c $(CONFIGURATION) -o $(PUBLISH_DIR) --runtime $(RUNTIME) --self-contained false
	@ls $(PUBLISH_DIR) | grep web.config >/dev/null || (echo "❌ Missing web.config — check your project or runtime target!" && exit 1)

# Step 3: Create deployment zip (flatten folder structure)
zip:
	@echo "📦 Creating deployment package..."
	@cd $(PUBLISH_DIR) && zip -r ../CustomerSite.zip ./* -q
	@echo "✅ Package created at $(ZIP_PATH)"

# Step 4: Deploy to Azure Web App
push:
	@echo "🚀 Deploying to Azure Web App: $(APP_NAME)"
	@az webapp deploy \
		--resource-group $(RESOURCE_GROUP) \
		--name $(APP_NAME) \
		--src-path "$(ZIP_PATH)" \
		--type zip
	@echo "✅ Deployment pushed to Azure."

# Step 5: Restart the App Service
restart:
	@echo "🔄 Restarting Azure Web App..."
	@az webapp restart --resource-group $(RESOURCE_GROUP) --name $(APP_NAME)
	@echo "✅ App restarted successfully."

# Utility target for checking environment
status:
	@az webapp show --resource-group $(RESOURCE_GROUP) --name $(APP_NAME) --query "[name, state, defaultHostName]" -o table
