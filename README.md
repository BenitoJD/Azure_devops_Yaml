# Independent Stakeholder Website Deployment Pipeline

This pipeline deploys 4 **independent main websites** for different stakeholders with branch-based naming and version management capabilities.

## Features

- **4 Independent Websites**: Each stakeholder gets their own main website
- **Separate Application Pools**: Each website has its own dedicated app pool
- **Branch-based Naming**: Folders are named using branch and build information
- **Version Management**: Automatic backup and metadata tracking
- **Rollback Capability**: Easy rollback to previous versions
- **Health Monitoring**: Automatic health checks after deployment
- **Auto-Creation**: Automatically creates any missing IIS components

## Independent Stakeholder Websites

| Stakeholder | Port | URL | Site Name | App Pool | Purpose |
|-------------|------|-----|-----------|----------|---------|
| Finance | 8091 | http://localhost:8091 | Finance.Main | FinanceAppPool | Financial team access |
| Operations | 8092 | http://localhost:8092 | Operations.Main | OperationsAppPool | Operations team access |
| Management | 8093 | http://localhost:8093 | Management.Main | ManagementAppPool | Management team access |
| Partners | 8094 | http://localhost:8094 | Partners.Main | PartnersAppPool | External partners access |

## Branch-based Folder Naming

Folders are automatically named using the pattern: `{Stakeholder}_{BranchName}_{BuildNumber}`

Example: `Finance_main_123` or `Operations_feature_new-ui_456`

## Version Management

### Automatic Backups
- Pre-deployment backups are created automatically
- Metadata is stored in `C:\VersionMetadata`
- Backups are stored in `C:\Backups\MasterData`

### Rollback Process

#### Using Azure DevOps Portal (Recommended)
1. **Navigate to Azure DevOps** → Your Project → Pipelines
2. **Select your pipeline** → Click "Run pipeline"
3. **Choose the branch** with the working build
4. **Select specific commit/build** you want to redeploy
5. **Click "Run"** to redeploy that exact build

#### Using Azure CLI (Alternative)
```bash
# List available builds
az pipelines runs list --pipeline-ids YOUR_PIPELINE_ID

# Redeploy specific build
az pipelines run --name "Your-Pipeline-Name" --branch "main" --commit-id "WORKING_COMMIT_ID"
```

## Deployment Process

1. **Backup**: Current deployments are backed up with metadata
2. **Extract**: Build artifacts are extracted
3. **Configure**: IIS site and application pool are configured
4. **Deploy**: Files are copied to stakeholder directories
5. **Create Apps**: Web applications are created for each stakeholder
6. **Set Permissions**: Folder permissions are configured
7. **Start Services**: Application pool and website are started

## File Structure

```
D:\inetpub\wwwroot\
├── Finance.Main\     # Finance independent website
├── Operations.Main\  # Operations independent website
├── Management.Main\  # Management independent website
└── Partners.Main\    # Partners independent website

D:\Backups\MasterData\
├── Finance_20241201_143022\    # Backup folders
├── Operations_20241201_143022\
├── Management_20241201_143022\
└── Partners_20241201_143022\

D:\VersionMetadata\
├── Finance_Deployment_20241201_143022.json    # Deployment metadata
├── Finance_Backup_20241201_143022.json       # Backup metadata
└── Finance_Rollback_20241201_143022.json     # Rollback metadata
```

## Rollback Scenarios (Build-Based)

### Scenario 1: Redeploy Previous Working Build
If something breaks, redeploy the last working build:
1. **Go to Azure DevOps Portal** → Pipelines → Your Pipeline
2. **Click "Run pipeline"** button
3. **Select the branch** with the working build
4. **Choose the specific commit/build** you want to redeploy
5. **Click "Run"** to redeploy that exact build

### Scenario 2: Emergency Redeploy
For emergency situations:
1. **Identify the last working build** in Azure DevOps
2. **Note the build number** and commit ID
3. **Redeploy that specific build** using the pipeline
4. **Monitor the deployment** to ensure success

### Scenario 3: All Stakeholders Need Rollback
If all websites need to go back to a previous version:
1. **Find the last working build** for all stakeholders
2. **Redeploy that build** using the pipeline
3. **Verify all websites** are working correctly

## Monitoring and Maintenance

### Health Checks
- Automatic health checks after deployment
- Manual health checks using the version manager
- IIS status monitoring

### Cleanup
- Automatic cleanup of old backups (keeps last 10)
- Manual cleanup using version manager
- Metadata file management

## Troubleshooting

### Common Issues

1. **Website not accessible**
   - Check IIS status
   - Verify port bindings
   - Check application pool status

2. **Permission issues**
   - Verify IIS_IUSRS permissions
   - Check folder permissions

3. **Rollback fails**
   - Verify backup exists
   - Check file permissions
   - Ensure services are stopped

### Logs and Monitoring
- Check Azure DevOps pipeline logs
- Review PowerShell execution logs
- Monitor IIS logs in `C:\inetpub\logs\LogFiles`

## Best Practices

1. **Always backup before deployment**
2. **Test rollback procedures regularly**
3. **Monitor disk space for backups**
4. **Keep deployment metadata organized**
5. **Use meaningful branch names for easy identification**
