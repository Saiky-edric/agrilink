#!/bin/bash

# Agrilink Digital Marketplace - Environment Setup Script
# This script helps you set up your environment configuration quickly

echo "🚀 Agrilink Environment Setup Script"
echo "======================================"

# Check if .env already exists
if [ -f ".env" ]; then
    echo "⚠️  .env file already exists!"
    echo "Do you want to:"
    echo "1) Backup existing and create new"
    echo "2) Edit existing file"
    echo "3) Cancel"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            mv .env .env.backup.$(date +%Y%m%d_%H%M%S)
            echo "✅ Existing .env backed up"
            ;;
        2)
            echo "✅ Opening existing .env file for editing..."
            # Try different editors
            if command -v code &> /dev/null; then
                code .env
            elif command -v nano &> /dev/null; then
                nano .env
            elif command -v vim &> /dev/null; then
                vim .env
            else
                echo "📝 Please edit .env manually with your preferred editor"
            fi
            exit 0
            ;;
        3)
            echo "❌ Setup cancelled"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            exit 1
            ;;
    esac
fi

# Copy template
echo "📋 Creating .env from template..."
cp .env.example .env

echo "✅ .env file created!"
echo ""
echo "🔧 Next Steps:"
echo "1. Get your Supabase credentials:"
echo "   - Go to: https://supabase.com/dashboard"
echo "   - Select your project (or create one)"
echo "   - Go to Settings → API"
echo "   - Copy Project URL and anon/public key"
echo ""
echo "2. Edit .env file and replace placeholders:"
echo "   - SUPABASE_URL=https://your-project.supabase.co"
echo "   - SUPABASE_ANON_KEY=your_actual_key_here"
echo ""
echo "3. (Optional) Configure OAuth providers:"
echo "   - Google: https://console.developers.google.com/"
echo "   - Facebook: https://developers.facebook.com/apps/"
echo ""
echo "4. Validate your configuration:"
echo "   dart run scripts/validate_env.dart"
echo ""
echo "5. Run the app:"
echo "   flutter run --dart-define-from-file=.env"
echo ""
echo "📚 For detailed instructions, see: ENVIRONMENT_SETUP_GUIDE.md"

# Try to open .env for editing
echo ""
echo "📝 Opening .env for editing..."
if command -v code &> /dev/null; then
    code .env
    echo "✅ Opened in VS Code"
elif command -v nano &> /dev/null; then
    nano .env
elif command -v vim &> /dev/null; then
    vim .env
else
    echo "⚠️  Please edit .env manually with your preferred editor"
fi