require 'rails_helper'

RSpec.describe User do
  describe 'create_user_with_fake_pw!' do
    context 'with login and email' do
      let(:user) { User.create_user_with_fake_pw!(login: 'tux', email: 'some@email.com') }

      it 'creates a user with a fake password' do
        expect(user.password).not_to eq(User.create_user_with_fake_pw!(login: 'tux2', email: 'some@email.com').password)
      end

      it 'creates a user from given attributes' do
        expect(user).to be_an(User)
        expect(user.login).to eq('tux')
        expect(user.email).to eq('some@email.com')
      end
    end

    context 'without params' do
      it 'throws an exception' do
        expect { User.create_user_with_fake_pw! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'create_user_with_fake_pw!' do
    context 'with login and email' do
      let(:user) { User.create_user_with_fake_pw!(login: 'tux', email: 'some@email.com') }

      it 'creates a user with a fake password' do
        expect(user.password).not_to eq(User.create_user_with_fake_pw!(login: 'tux2', email: 'some@email.com').password)
      end

      it 'creates a user from given attributes' do
        expect(user).to be_an(User)
        expect(user.login).to eq('tux')
        expect(user.email).to eq('some@email.com')
      end
    end

    context 'without params' do
      it 'throws an exception' do
        expect { User.create_user_with_fake_pw! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  shared_examples 'password comparison' do
    context 'with invalid credentials' do
      it 'returns false' do
        expect(user.authenticate('invalid_password')).to eq(false)
      end
    end

    context 'with valid credentials' do
      it 'returns a user object for valid credentials' do
        expect(user.authenticate('buildservice')).to eq(user)
      end
    end
  end

  describe '#authenticate' do
    context 'as a user which has a deprecated password' do
      let(:user) { create(:user_deprecated_password) }

      context 'conversation of deprecated password' do
        before do
          user.authenticate('buildservice')
        end

        it 'converts the password to bcrypt' do
          expect(BCrypt::Password.new(user.password_digest).is_password?('buildservice')).to be_truthy
        end

        it 'resets the hash of the deprecated password' do
          expect(user.deprecated_password).to be(nil)
        end

        it 'resets the hash type of the deprecated password' do
          expect(user.deprecated_password_hash_type).to be(nil)
        end

        it 'resets the salt of the deprecated password' do
          expect(user.deprecated_password_salt).to be(nil)
        end
      end

      it_behaves_like 'password comparison'
    end

    context 'as a user which has a bcrypt password' do
      it_behaves_like 'password comparison'
    end
  end

  describe '.mark_login!' do
    before do
      user.update_attributes!(login_failure_count: 7, last_logged_in_at: 3.hours.ago)
      user.mark_login!
    end

    it "updates the 'last_logged_in_at'" do
      expect(user.last_logged_in_at).to be > 30.seconds.ago
    end

    it "resets the 'login_failure_count'" do
      expect(user.reload.login_failure_count).to eq 0
    end
  end

  describe '#find_with_credentials' do
    let(:user) { create(:user, login: 'login_test', login_failure_count: 7, last_logged_in_at: 3.hours.ago) }

    context 'when user exists' do
      subject { User.find_with_credentials(user.login, 'buildservice') }

      it { is_expected.to eq user }
      it { expect(subject.login_failure_count).to eq 0 }
      it { expect(subject.last_logged_in_at).to be > 30.seconds.ago }
    end

    context 'when user does not exist' do
      it { expect(User.find_with_credentials('unknown', 'buildservice')).to be nil }
    end

    context 'when user exist but password was incorrect' do
      before do
        @found_user = User.find_with_credentials(user.login, '_buildservice')
      end

      it { expect(@found_user).to be nil }
      it { expect(user.reload.login_failure_count).to eq 8 }
    end

    context 'when LDAP mode is enabled' do
      include_context 'setup ldap mock with user mock', for_ssl: true
      include_context 'an ldap connection'
      include_context 'mock searching a user' do
        let(:ldap_user) { double(:ldap_user, to_hash: { 'dn' => 'tux', 'sn' => ['John@obs.de', 'John', 'Smith'] }) }
      end

      let(:user) do
        create(:user, login: 'tux', realname: 'penguin', login_failure_count: 7, last_logged_in_at: 3.hours.ago, email: 'tux@suse.de')
      end

      before do
        stub_const('CONFIG', CONFIG.merge('ldap_mode'        => :on,
                                          'ldap_search_user' => 'tux',
                                          'ldap_search_auth' => 'tux_password'))
      end

      context 'and user is already known by OBS' do
        subject { User.find_with_credentials(user.login, 'tux_password') }

        it { is_expected.to eq user }
        it { expect(subject.login_failure_count).to eq 0 }
        it { expect(subject.last_logged_in_at).to be > 30.seconds.ago }

        it 'updates user data received from the LDAP server' do
          expect(subject.email).to eq 'John@obs.de'
          expect(subject.realname).to eq 'tux'
        end
      end

      context 'and user is not yet known by OBS' do
        subject { User.find_with_credentials('new_user', 'tux_password') }

        it 'creates a new user from the data received by the LDAP server' do
          expect { subject }.to change { User.count }.by 1
          expect(subject.email).to eq 'John@obs.de'
          expect(subject.login).to eq 'new_user'
          expect(subject.realname).to eq 'new_user'
          expect(subject.state).to eq 'confirmed'
          expect(subject.login_failure_count).to eq 0
          expect(subject.last_logged_in_at).to be > 30.seconds.ago
        end
      end
    end
  end
end
